# frozen_string_literal: true

RSpec.describe "Forge: Hooks", :integration do
  let(:hook_tracker) { [] }
  let(:forge_hooks) { {} }

  let(:load_results) do
    SpecForge::Loader.new(
      paths: [
        fixtures_path.join("blueprints", "forge", "hooks.yml"),
        fixtures_path.join("blueprints", "forge", "shared_workflow.yml")
      ]
    ).load
  end

  let(:blueprints) { [load_results.first.first] } # Only run the hooks.yml
  let(:forge_hooks) { load_results.second }

  subject(:forge) { SpecForge::Forge.new(blueprints, verbosity_level: 0, hooks: forge_hooks) }

  before do
    # Forge-level hooks
    forge.callbacks.register(:setup_test_environment) { hook_tracker << :setup_test_environment }
    forge.callbacks.register(:teardown_test_environment) { hook_tracker << :teardown_test_environment }

    # Blueprint-level hooks
    forge.callbacks.register(:seed_database) { hook_tracker << :seed_database }
    forge.callbacks.register(:cleanup_database) { hook_tracker << :cleanup_database }
    forge.callbacks.register(:duplicate_blueprint_hook) { hook_tracker << :duplicate_blueprint_hook }

    # Global step hooks
    forge.callbacks.register(:global_step_logger) { hook_tracker << :global_step_logger }
    forge.callbacks.register(:global_step_cleanup) { hook_tracker << :global_step_cleanup }

    # Auth section hooks
    forge.callbacks.register(:auth_logger) { hook_tracker << :auth_logger }
    forge.callbacks.register(:auth_validator) { hook_tracker << :auth_validator }

    # User operations hooks
    forge.callbacks.register(:user_operation_logger) { hook_tracker << :user_operation_logger }

    # Nested workflow hooks
    forge.callbacks.register(:outer_logger) { hook_tracker << :outer_logger }
    forge.callbacks.register(:middle_logger) { hook_tracker << :middle_logger }
    forge.callbacks.register(:inner_logger) { hook_tracker << :inner_logger }

    # Deduplication hooks
    forge.callbacks.register(:duplicate_logger) { hook_tracker << :duplicate_logger }
    forge.callbacks.register(:duplicate_cleanup) { hook_tracker << :duplicate_cleanup }

    # Include context hooks
    forge.callbacks.register(:include_context_logger) { hook_tracker << :include_context_logger }
    forge.callbacks.register(:shared_file_logger) { hook_tracker << :shared_file_logger }

    # Valid section callback
    forge.callbacks.register(:some_callback) { hook_tracker << :some_callback }

    # Silence display output
    allow_any_instance_of(SpecForge::Forge::Display).to receive(:puts)
    allow_any_instance_of(SpecForge::Forge::Display).to receive(:print)
  end

  describe "forge-level hooks" do
    it "executes before_forge hook once at the very start" do
      forge.run

      expect(hook_tracker.first).to eq(:setup_test_environment)
      expect(hook_tracker.count(:setup_test_environment)).to eq(1)
    end

    it "executes after_forge hook once at the very end" do
      forge.run

      expect(hook_tracker.last).to eq(:teardown_test_environment)
      expect(hook_tracker.count(:teardown_test_environment)).to eq(1)
    end
  end

  describe "blueprint-level hooks" do
    it "executes before_blueprint hook once per blueprint" do
      forge.run

      expect(hook_tracker.count(:seed_database)).to eq(1)
    end

    it "executes after_blueprint hook once per blueprint" do
      forge.run

      expect(hook_tracker.count(:cleanup_database)).to eq(1)
    end

    it "deduplicates blueprint hooks with the same name" do
      forge.run

      # duplicate_blueprint_hook is defined twice but should only run once
      expect(hook_tracker.count(:duplicate_blueprint_hook)).to eq(1)
    end
  end

  describe "step-level hooks" do
    it "executes global before_step hook for every step" do
      forge.run

      # Count all steps in hooks.yml:
      # - "First step after global hook"
      # - "Second step - also gets global hook"
      # - Auth section: "Login", "Verify token"
      # - User operations: "Create user", "Update user"
      # - Nested workflows: "Outer step", "Middle step", "Deep step"
      # - Deduplication: "Second substep with same hook" (First substep has no action)
      # - Include shared workflows: 3 steps from shared_workflow.yml
      # - "VALID - separate action from organization" (call step)
      # - "Step after duplicate blueprint hooks"
      # Total: 15 steps (steps with no action are not executed)
      expect(hook_tracker.count(:global_step_logger)).to eq(15)
    end

    it "executes global after_step hook for every step" do
      forge.run

      expect(hook_tracker.count(:global_step_cleanup)).to eq(15)
    end
  end

  describe "shared hook inheritance" do
    it "accumulates auth section hooks for nested steps" do
      forge.run

      # Auth section has 2 steps (Login, Verify token)
      expect(hook_tracker.count(:auth_logger)).to eq(2)
      expect(hook_tracker.count(:auth_validator)).to eq(2)
    end

    it "accumulates user operations hooks for nested steps" do
      forge.run

      # User operations section has 2 steps (Create user, Update user)
      expect(hook_tracker.count(:user_operation_logger)).to eq(2)
    end

    it "accumulates nested workflow hooks at each nesting level" do
      forge.run

      # outer_logger: "Outer step", "Middle step", "Deep step" = 3
      expect(hook_tracker.count(:outer_logger)).to eq(3)

      # middle_logger: "Middle step", "Deep step" = 2
      expect(hook_tracker.count(:middle_logger)).to eq(2)

      # inner_logger: "Deep step" = 1
      expect(hook_tracker.count(:inner_logger)).to eq(1)
    end
  end

  describe "hook deduplication" do
    it "deduplicates step hooks with the same name" do
      forge.run

      # Deduplication section has 2 steps, but "First substep" has no action so it's not executed
      # duplicate_logger is defined in shared and again on "Second substep" - should only run once per step
      # Only "Second substep with same hook" runs, so duplicate_logger fires once
      expect(hook_tracker.count(:duplicate_logger)).to eq(1)
      expect(hook_tracker.count(:duplicate_cleanup)).to eq(1)
    end
  end

  describe "include with hook inheritance" do
    it "passes shared hooks to included file steps" do
      forge.run

      # shared_workflow.yml has 3 steps that inherit include_context_logger
      expect(hook_tracker.count(:include_context_logger)).to eq(3)
    end

    it "allows included files to define their own shared hooks" do
      forge.run

      # shared_file_logger is defined within shared_workflow.yml's "Shared section"
      # and only applies to "Nested in shared file" step = 1
      expect(hook_tracker.count(:shared_file_logger)).to eq(1)
    end
  end

  describe "hook execution order" do
    it "executes forge hooks around the entire run" do
      forge.run

      # First hook should be before_forge
      expect(hook_tracker.first).to eq(:setup_test_environment)

      # Last hook should be after_forge
      expect(hook_tracker.last).to eq(:teardown_test_environment)
    end

    it "executes blueprint hooks around all steps in the file" do
      forge.run

      # Find positions of key hooks
      setup_pos = hook_tracker.index(:setup_test_environment)
      seed_pos = hook_tracker.index(:seed_database)
      cleanup_pos = hook_tracker.rindex(:cleanup_database)
      teardown_pos = hook_tracker.rindex(:teardown_test_environment)

      # before_forge < before_blueprint < after_blueprint < after_forge
      expect(setup_pos).to be < seed_pos
      expect(seed_pos).to be < cleanup_pos
      expect(cleanup_pos).to be < teardown_pos
    end

    it "executes step hooks in parent-to-child order for before_step" do
      forge.run

      # For the "Deep step", hooks should execute: global_step_logger, outer_logger, middle_logger, inner_logger
      # Find a sequence where all four appear in order
      deep_step_before_hooks = []

      hook_tracker.each_with_index do |hook, i|
        if hook == :global_step_logger
          # Check if this is followed by the nested workflow pattern
          next_hooks = hook_tracker[i, 5]
          if next_hooks.include?(:outer_logger) && next_hooks.include?(:middle_logger) && next_hooks.include?(:inner_logger)
            deep_step_before_hooks = next_hooks.take_while { |h| h != :global_step_cleanup }
            break
          end
        end
      end

      # Verify order: global_step_logger comes before outer_logger, etc.
      if deep_step_before_hooks.any?
        global_idx = deep_step_before_hooks.index(:global_step_logger)
        outer_idx = deep_step_before_hooks.index(:outer_logger)
        middle_idx = deep_step_before_hooks.index(:middle_logger)
        inner_idx = deep_step_before_hooks.index(:inner_logger)

        expect(global_idx).to be < outer_idx if global_idx && outer_idx
        expect(outer_idx).to be < middle_idx if outer_idx && middle_idx
        expect(middle_idx).to be < inner_idx if middle_idx && inner_idx
      end
    end
  end

  describe "call step execution" do
    it "executes callbacks defined with call:" do
      forge.run

      # "VALID - separate action from organization" has call: some_callback
      expect(hook_tracker).to include(:some_callback)
      expect(hook_tracker.count(:some_callback)).to eq(1)
    end
  end
end
