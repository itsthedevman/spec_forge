# frozen_string_literal: true

RSpec.describe SpecForge::Loader::StepProcessor do
  let(:base_path) { fixtures_path.join("blueprints", "step_processor") }
  let(:blueprints) { {} }

  subject(:processor) { described_class.new(blueprints) }

  describe ".assign_source" do
    let(:steps) do
      [
        {name: "Step 1", line_number: 10},
        {
          name: "Step 2", line_number: 15,
          steps: [
            {name: "Nested Step", line_number: 16}
          ]
        }
      ]
    end

    it "is expected to assign source metadata to root steps" do
      result = processor.send(:assign_source, steps, file_name: "test.yml")

      expect(result[0][:source]).to eq({file_name: "test.yml", line_number: 10})
      expect(result[1][:source]).to eq({file_name: "test.yml", line_number: 15})
    end

    it "is expected to recursively assign source to nested steps" do
      result = processor.send(:assign_source, steps, file_name: "test.yml")

      expect(result[1][:steps][0][:source]).to eq({file_name: "test.yml", line_number: 16})
    end

    it "is expected to remove line_number key after conversion" do
      result = processor.send(:assign_source, steps, file_name: "test.yml")

      expect(result[0]).not_to have_key(:line_number)
      expect(result[1]).not_to have_key(:line_number)
    end
  end

  describe ".normalize_steps" do
    let(:steps) do
      [
        {name: "Valid Step", tags: ["test"]},
        {
          name: "Step with nested",
          steps: [
            {name: "Nested Step"}
          ]
        }
      ]
    end

    it "is expected to normalize each step using Normalizer" do
      allow(SpecForge::Normalizer).to receive(:normalize!).and_call_original

      processor.send(:normalize_steps, steps)

      expect(SpecForge::Normalizer).to have_received(:normalize!).at_least(:once)
    end

    it "is expected to preserve nested steps during normalization" do
      result = processor.send(:normalize_steps, steps)

      expect(result[1][:steps].size).to eq(1)
      expect(result[1][:steps][0][:name]).to eq("Nested Step")
    end

    it "is expected to rename call to calls and expect to expects" do
      steps_with_call = [{name: "Step", call: {name: "test_callback"}, expect: [{status: 200}]}]

      result = processor.send(:normalize_steps, steps_with_call)

      expect(result[0]).to have_key(:calls)
      expect(result[0]).to have_key(:expects)
      expect(result[0]).not_to have_key(:call)
      expect(result[0]).not_to have_key(:expect)
    end

    context "when normalization fails" do
      let(:steps) do
        [{name: 123}] # Invalid type for name field
      end

      it "is expected to wrap errors in LoadStepError" do
        expect { processor.send(:normalize_steps, steps) }
          .to raise_error(SpecForge::Error::LoadStepError)
      end
    end
  end

  describe ".tag_steps" do
    context "when steps use tags" do
      let(:steps) do
        [
          {
            name: "Parent Step",
            tags: ["parent", "shared"],
            steps: [
              {name: "Child Step 1", tags: ["child1"]},
              {
                name: "Child Step 2",
                tags: ["child2", "shared"],
                steps: [
                  {name: "Grandchild Step", tags: ["grandchild"]}
                ]
              }
            ]
          }
        ]
      end

      it "is expected to assign inherited tags to sub-steps" do
        processor.send(:tag_steps, steps)

        child1 = steps[0][:steps][0]
        child2 = steps[0][:steps][1]
        grandchild = child2[:steps][0]

        expect(child1[:tags]).to eq(["parent", "shared", "child1"])
        expect(child2[:tags]).to eq(["parent", "shared", "child2"])
        expect(grandchild[:tags]).to eq(["parent", "shared", "child2", "grandchild"])
      end

      it "is expected to deduplicate tags when parent and child share same tag" do
        processor.send(:tag_steps, steps)

        child2 = steps[0][:steps][1]

        expect(child2[:tags]).to eq(["parent", "shared", "child2"])
        expect(child2[:tags].count("shared")).to eq(1)
      end

      it "is expected to preserve parent tags unchanged" do
        original_tags = steps[0][:tags].dup
        processor.send(:tag_steps, steps)

        expect(steps[0][:tags]).to eq(original_tags)
      end
    end

    context "when steps have empty tags" do
      let(:steps) do
        [
          {
            name: "Parent",
            tags: [],
            steps: [
              {name: "Child", tags: ["child"]}
            ]
          }
        ]
      end

      it "is expected to handle empty parent tags correctly" do
        processor.send(:tag_steps, steps)

        expect(steps[0][:steps][0][:tags]).to eq(["child"])
      end
    end

    context "when processing multiple nesting levels" do
      let(:steps) do
        [
          {
            name: "Level 1",
            tags: ["l1"],
            steps: [
              {
                name: "Level 2",
                tags: ["l2"],
                steps: [
                  {
                    name: "Level 3",
                    tags: ["l3"],
                    steps: [
                      {name: "Level 4", tags: ["l4"]}
                    ]
                  }
                ]
              }
            ]
          }
        ]
      end

      it "is expected to cascade tags through all levels" do
        processor.send(:tag_steps, steps)

        level4 = steps[0][:steps][0][:steps][0][:steps][0]

        expect(level4[:tags]).to eq(["l1", "l2", "l3", "l4"])
      end
    end
  end

  describe ".expand_steps" do
    context "when steps use include" do
      let(:blueprints) do
        {
          "auth_setup" => {
            file_path: base_path.join("auth_setup.yml"),
            file_name: "auth_setup.yml",
            name: "auth_setup",
            steps: [
              {name: "Login as admin", tags: ["auth", "login"]},
              {name: "Get auth token", tags: ["auth", "token"]}
            ]
          }
        }
      end

      context "with a single include" do
        let(:steps) do
          [
            {name: "Before", tags: [], steps: []},
            {
              include: ["auth_setup"],
              tags: ["bootstrap"],
              steps: [],
              source: {file_name: "test.yml", line_number: 2}
            },
            {name: "After", tags: [], steps: []}
          ]
        end

        it "is expected to replace include with actual steps" do
          result = processor.send(:expand_steps, steps)

          # The include step is kept but its :steps array is populated
          expect(result.size).to eq(3)
          expect(result[0][:name]).to eq("Before")
          expect(result[1][:steps].size).to eq(2)
          expect(result[1][:steps][0][:name]).to eq("Login as admin")
          expect(result[1][:steps][1][:name]).to eq("Get auth token")
          expect(result[2][:name]).to eq("After")
        end

        it "is expected to stamp included_by metadata" do
          result = processor.send(:expand_steps, steps)

          included_steps = result[1][:steps]
          expect(included_steps[0][:included_by]).to have_key(:file_name)
          expect(included_steps[1][:included_by]).to have_key(:file_name)
        end

        it "is expected to not modify the original blueprint steps" do
          original_step_count = blueprints["auth_setup"][:steps].size

          processor.send(:expand_steps, steps)

          expect(blueprints["auth_setup"][:steps].size).to eq(original_step_count)
        end
      end

      context "with multiple includes in array" do
        let(:blueprints) do
          {
            "auth_setup" => {
              file_path: base_path.join("auth_setup.yml"),
              file_name: "auth_setup.yml",
              name: "auth_setup",
              steps: [
                {name: "Login as admin", tags: []}
              ]
            },
            "database" => {
              file_path: base_path.join("database.yml"),
              file_name: "database.yml",
              name: "database",
              steps: [
                {name: "Create database", tags: []}
              ]
            }
          }
        end

        let(:steps) do
          [
            {include: ["auth_setup", "database"], tags: [], steps: []}
          ]
        end

        it "is expected to include steps from all blueprints" do
          result = processor.send(:expand_steps, steps)

          expect(result.size).to eq(1)
          included_steps = result[0][:steps]
          expect(included_steps.size).to eq(2)
          expect(included_steps[0][:name]).to eq("Login as admin")
          expect(included_steps[1][:name]).to eq("Create database")
        end
      end

      context "with nested includes" do
        let(:blueprints) do
          {
            "auth_setup" => {
              file_path: base_path.join("auth_setup.yml"),
              file_name: "auth_setup.yml",
              name: "auth_setup",
              steps: [
                {name: "Login", tags: []}
              ]
            },
            "wrapper" => {
              file_path: base_path.join("wrapper.yml"),
              file_name: "wrapper.yml",
              name: "wrapper",
              steps: [
                {include: ["auth_setup"], tags: [], steps: []},
                {name: "Additional Step", tags: [], steps: []}
              ]
            }
          }
        end

        let(:steps) do
          [
            {include: ["wrapper"], tags: [], steps: []}
          ]
        end

        it "is expected to recursively expand includes" do
          result = processor.send(:expand_steps, steps)

          # The wrapper is kept, with its nested steps expanded
          expect(result.size).to eq(1)
          wrapper_steps = result[0][:steps]
          expect(wrapper_steps.size).to eq(2)

          # First step had an include, so it should have nested steps now
          expect(wrapper_steps[0][:steps].size).to eq(1)
          expect(wrapper_steps[0][:steps][0][:name]).to eq("Login")

          # Second step is a regular step
          expect(wrapper_steps[1][:name]).to eq("Additional Step")
        end
      end

      context "with tags on include directive" do
        let(:blueprints) do
          {
            "auth_setup" => {
              file_path: base_path.join("auth_setup.yml"),
              file_name: "auth_setup.yml",
              name: "auth_setup",
              steps: [
                {name: "Login", tags: ["auth"]}
              ]
            }
          }
        end

        let(:steps) do
          [
            {include: ["auth_setup"], tags: ["bootstrap", "setup"], steps: []}
          ]
        end

        it "is expected to keep the include step with imported steps nested" do
          result = processor.send(:expand_steps, steps)

          # expand_steps doesn't apply tags, that's done by tag_steps
          # The include step is kept with its steps populated
          expect(result.size).to eq(1)
          expect(result[0][:steps].size).to eq(1)
          expect(result[0][:steps][0][:name]).to eq("Login")
        end
      end

      context "when blueprint is not found" do
        let(:steps) do
          [
            {
              include: ["nonexistent"],
              tags: [], steps: [],
              source: {file_name: "test.yml", line_number: 1}
            }
          ]
        end

        it "is expected to raise an error" do
          expect { processor.send(:expand_steps, steps) }
            .to raise_error(/Blueprint.*not found/)
        end
      end
    end

    context "when steps have no includes" do
      let(:steps) do
        [
          {name: "Regular Step", tags: []}
        ]
      end

      it "is expected to return steps unchanged" do
        result = processor.send(:expand_steps, steps)

        expect(result.size).to eq(1)
        expect(result[0][:name]).to eq("Regular Step")
      end
    end
  end

  describe ".flatten_steps" do
    let(:steps) do
      [
        {name: "Root", tags: ["root"]},
        {
          name: "Parent",
          tags: ["parent"],
          steps: [
            {name: "Child", tags: ["child"]},
            {
              name: "Child with nested",
              tags: ["child2"],
              steps: [
                {name: "Grandchild", tags: ["grandchild"]}
              ]
            }
          ]
        }
      ]
    end

    it "is expected to flatten nested hierarchy into single array" do
      result = processor.send(:flatten_steps, steps)

      # Only leaf steps (those without nested steps) are included
      expect(result.size).to eq(3)
      expect(result.map { |s| s[:name] }).to eq([
        "Root",
        "Child",
        "Grandchild"
      ])
    end

    it "is expected to remove steps key from all returned steps" do
      result = processor.send(:flatten_steps, steps)

      result.each do |step|
        expect(step).not_to have_key(:steps)
      end
    end

    it "is expected to preserve all other step data" do
      result = processor.send(:flatten_steps, steps)

      expect(result[0][:tags]).to eq(["root"])
      expect(result[1][:tags]).to eq(["child"])
      expect(result[2][:tags]).to eq(["grandchild"])
    end
  end

  describe ".inherit_shared" do
    context "with shared request configuration" do
      let(:steps) do
        [
          {
            name: "Parent",
            shared: {
              request: {headers: {"Authorization" => "Bearer token"}}
            },
            steps: [
              {
                name: "Child",
                request: {url: "/users"}
              }
            ]
          }
        ]
      end

      it "merges shared request into child steps" do
        processor.send(:inherit_shared, steps)

        child = steps[0][:steps][0]
        expect(child[:request]).to include(
          headers: {"Authorization" => "Bearer token"},
          url: "/users"
        )
      end
    end

    context "with overlapping shared values" do
      let(:steps) do
        [
          {
            name: "Parent",
            shared: {
              request: {
                headers: {"Authorization" => "Bearer old", "X-App" => "1.0"}
              }
            },
            steps: [
              {
                name: "Child",
                request: {
                  url: "/users",
                  headers: {"Authorization" => "Bearer new"}
                }
              }
            ]
          }
        ]
      end

      it "lets child values override shared values" do
        processor.send(:inherit_shared, steps)

        child = steps[0][:steps][0]
        expect(child[:request][:headers]).to eq({
          "Authorization" => "Bearer new",  # Child wins
          "X-App" => "1.0"                  # Parent preserved
        })
      end
    end

    context "with multiple nesting levels" do
      let(:steps) do
        [
          {
            name: "L1",
            shared: {request: {headers: {"X-Level" => "1"}}},
            steps: [
              {
                name: "L2",
                shared: {request: {headers: {"X-Level" => "2"}}},
                steps: [
                  {
                    name: "L3",
                    request: {url: "/deep"}
                  }
                ]
              }
            ]
          }
        ]
      end

      it "cascades through all levels with child winning" do
        processor.send(:inherit_shared, steps)

        l3 = steps[0][:steps][0][:steps][0]
        expect(l3[:request][:headers]).to eq({"X-Level" => "2"})
        expect(l3[:request][:url]).to eq("/deep")
      end
    end

    context "with shared hooks" do
      let(:steps) do
        [
          {
            name: "Parent",
            shared: {
              hook: {before_step: [{name: "parent_hook"}]}
            },
            steps: [
              {
                name: "Child",
                hook: {before_step: [{name: "child_hook"}]}
              }
            ]
          }
        ]
      end

      it "merges shared hooks into child steps" do
        processor.send(:inherit_shared, steps)

        child = steps[0][:steps][0]

        # Arrays are concatenated, so both hooks should be present
        expect(child[:hook][:before_step]).to include(
          {name: "parent_hook"},
          {name: "child_hook"}
        )
      end
    end

    context "with deeply nested shared hooks" do
      let(:steps) do
        [
          {
            name: "Section",
            shared: {
              hook: {before_step: [{name: "middle_logger"}]}
            },
            steps: [
              {
                name: "Subsection",
                shared: {
                  hook: {before_step: [{name: "inner_logger"}]}
                },
                steps: [
                  {
                    name: "Deep step",
                    hook: {before_step: [{name: "deep_hook"}]}
                  }
                ]
              }
            ]
          }
        ]
      end

      it "accumulates hooks through all nesting levels" do
        processor.send(:inherit_shared, steps)

        deep_step = steps[0][:steps][0][:steps][0]
        hook_names = deep_step[:hook][:before_step].map { |h| h[:name] }

        # Per tech-spec: hooks accumulate through nesting levels
        expect(hook_names).to eq(%w[middle_logger inner_logger deep_hook])
      end
    end

    context "with nil/blank shared" do
      let(:steps) do
        [
          {
            name: "Parent",
            shared: {},
            steps: [
              {
                name: "Child",
                request: {url: "/users"}
              }
            ]
          }
        ]
      end

      it "doesn't modify child" do
        processor.send(:inherit_shared, steps)

        child = steps[0][:steps][0]
        expect(child[:request]).to eq({url: "/users"})
      end
    end
  end

  describe "global hooks integration" do
    let(:blueprints) do
      {
        "test_blueprint" => {
          file_path: base_path.join("test.yml"),
          file_name: "test.yml",
          name: "test_blueprint",
          steps: [
            {name: "Test Step", tags: [], line_number: 1, request: {url: "/test"}}
          ]
        }
      }
    end

    before do
      SpecForge.configuration.register_callback(:forge_before) { |ctx| "forge before" }
      SpecForge.configuration.register_callback(:forge_after) { |ctx| "forge after" }
      SpecForge.configuration.register_callback(:blueprint_before) { |ctx| "blueprint before" }
      SpecForge.configuration.register_callback(:blueprint_after) { |ctx| "blueprint after" }
      SpecForge.configuration.register_callback(:step_before) { |ctx| "step before" }
      SpecForge.configuration.register_callback(:step_after) { |ctx| "step after" }

      SpecForge.configuration.before(:forge, :forge_before)
      SpecForge.configuration.after(:forge, :forge_after)
      SpecForge.configuration.before(:blueprint, :blueprint_before)
      SpecForge.configuration.after(:blueprint, :blueprint_after)
      SpecForge.configuration.before(:step, :step_before)
      SpecForge.configuration.after(:step, :step_after)
    end

    it "includes global forge hooks in forge_hooks" do
      _blueprints_result, forge_hooks = processor.run

      expect(forge_hooks[:before]).to include({name: :forge_before})
      expect(forge_hooks[:after]).to include({name: :forge_after})
    end

    it "includes global blueprint hooks in blueprint hooks" do
      blueprints_result, _forge_hooks = processor.run

      blueprint = blueprints_result.first
      expect(blueprint[:hooks][:before]).to include({name: :blueprint_before})
      expect(blueprint[:hooks][:after]).to include({name: :blueprint_after})
    end

    it "includes global step hooks in step hooks" do
      blueprints_result, _forge_hooks = processor.run

      step = blueprints_result.first[:steps].first
      expect(step[:hooks][:before]).to include({name: :step_before})
      expect(step[:hooks][:after]).to include({name: :step_after})
    end

    context "when combining global and local hooks" do
      before do
        SpecForge.configuration.register_callback(:local_step_before) { |ctx| "local before" }
        SpecForge.configuration.register_callback(:local_step_after) { |ctx| "local after" }
      end

      let(:blueprints) do
        {
          "test_blueprint" => {
            file_path: base_path.join("test.yml"),
            file_name: "test.yml",
            name: "test_blueprint",
            steps: [
              {
                name: "Test Step",
                tags: [],
                line_number: 1,
                request: {url: "/test"},
                hook: {
                  before_step: [{name: "local_step_before"}],
                  after_step: [{name: "local_step_after"}]
                }
              }
            ]
          }
        }
      end

      it "merges global and local step hooks" do
        blueprints_result, _forge_hooks = processor.run

        step = blueprints_result.first[:steps].first
        before_names = step[:hooks][:before].map { |h| h[:name].to_sym }
        after_names = step[:hooks][:after].map { |h| h[:name].to_sym }

        expect(before_names).to include(:step_before)
        expect(before_names).to include(:local_step_before)
        expect(after_names).to include(:step_after)
        expect(after_names).to include(:local_step_after)
      end
    end
  end

  describe ".run" do
    context "with full pipeline integration" do
      let(:blueprints) do
        {
          "auth_setup" => {
            file_path: base_path.join("auth_setup.yml"),
            file_name: "auth_setup.yml",
            name: "auth_setup",
            steps: [
              {name: "Login", tags: ["auth"], line_number: 1, request: {url: "/login"}},
              {name: "Token", tags: ["auth"], line_number: 5, request: {url: "/token"}}
            ]
          },
          "main" => {
            file_path: base_path.join("main.yml"),
            file_name: "main.yml",
            name: "main",
            steps: [
              {
                name: "Setup",
                tags: ["setup"],
                line_number: 1,
                include: ["auth_setup"]
              },
              {
                name: "Tests",
                tags: ["test"],
                line_number: 5,
                steps: [
                  {name: "Test 1", tags: [], line_number: 6, request: {url: "/test"}}
                ]
              }
            ]
          }
        }
      end

      it "is expected to return blueprints and forge_hooks tuple" do
        result = processor.run

        expect(result).to be_an(Array)
        expect(result.size).to eq(2)

        blueprints_result, forge_hooks = result
        expect(blueprints_result).to be_an(Array)
        expect(forge_hooks).to be_a(Hash)
        expect(forge_hooks).to have_key(:before)
        expect(forge_hooks).to have_key(:after)
      end

      it "is expected to process blueprints through full pipeline" do
        blueprints_result, _forge_hooks = processor.run

        main_result = blueprints_result.find { |bp| bp[:name] == "main" }
        steps = main_result[:steps]

        # Should have 3 steps total: Login and Token from auth_setup include, Test 1 from Tests
        # Setup and Tests parent steps are removed during flattening
        expect(steps.size).to eq(3)

        # All steps should be flattened (no nested steps)
        steps.each do |step|
          expect(step).not_to have_key(:steps)
        end

        # All steps should have source metadata
        steps.each do |step|
          expect(step[:source]).to have_key(:file_name)
          expect(step[:source]).to have_key(:line_number)
        end

        # Tags should be inherited
        expect(steps[2][:tags]).to include("test") # Test 1 inherits from Tests
      end

      it "is expected to return array of processed blueprints" do
        blueprints_result, _forge_hooks = processor.run

        expect(blueprints_result).to be_kind_of(Array)
        expect(blueprints_result.size).to eq(2)
        expect(blueprints_result.all? { |bp| bp.key?(:steps) }).to be true
      end
    end
  end
end
