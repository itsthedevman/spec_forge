# frozen_string_literal: true

RSpec.describe "Forge: Hooks", :integration do
  let(:hook_tracker) { [] }

  let(:blueprints) do
    SpecForge::Loader.new(base_path: fixtures_path.join("blueprints", "forge")).load
  end

  subject(:forge) { SpecForge::Forge.new(blueprints, verbosity_level: 0) }

  before do
    # Register the callbacks referenced in hooks.yml
    forge.callbacks.register(:seed_database) { hook_tracker << :seed_database }
    forge.callbacks.register(:cleanup_database) { hook_tracker << :cleanup_database }
    forge.callbacks.register(:log_step_start) { hook_tracker << :log_step_start }
    forge.callbacks.register(:log_step_end) { hook_tracker << :log_step_end }

    # Silence display output
    allow_any_instance_of(SpecForge::Forge::Display).to receive(:puts)
    allow_any_instance_of(SpecForge::Forge::Display).to receive(:print)
  end

  describe "hook execution" do
    it "executes before_blueprint hook once at the start" do
      forge.run

      expect(hook_tracker.first).to eq(:seed_database)
      expect(hook_tracker.count(:seed_database)).to eq(1)
    end

    it "executes after_blueprint hook once at the end" do
      forge.run

      expect(hook_tracker.last).to eq(:cleanup_database)
      expect(hook_tracker.count(:cleanup_database)).to eq(1)
    end

    it "executes before_each hook before every step" do
      forge.run

      # 2 steps in hooks.yml
      expect(hook_tracker.count(:log_step_start)).to eq(2)
    end

    it "executes after_each hook after every step" do
      forge.run

      # 2 steps in hooks.yml
      expect(hook_tracker.count(:log_step_end)).to eq(2)
    end

    it "executes hooks in correct order" do
      forge.run

      # Expected order for 2 debug steps:
      # 1. before_blueprint (seed_database)
      # 2. before_step (log_step_start) - First step
      # 3. after_step (log_step_end) - First step
      # 4. before_step (log_step_start) - Second step
      # 5. after_step (log_step_end) - Second step
      # 6. after_blueprint (cleanup_database)
      expect(hook_tracker).to eq([
        :seed_database,
        :log_step_start,
        :log_step_end,
        :log_step_start,
        :log_step_end,
        :cleanup_database
      ])
    end
  end
end
