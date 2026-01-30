# frozen_string_literal: true

RSpec.describe SpecForge::Loader do
  let(:base_path) { fixtures_path.join("loader", "blueprints") }
  let(:paths) { [] }
  let(:tags) { [] }
  let(:skip_tags) { [] }

  subject(:result) { described_class.load_blueprints(base_path:, paths:, tags:, skip_tags:) }

  let(:blueprints) { result.first }
  let(:forge_hooks) { result.last }

  describe "loading blueprints" do
    it "is expected to return blueprints and forge_hooks tuple" do
      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(blueprints).to be_an(Array)
      expect(forge_hooks).to be_a(Hash)
    end

    it "is expected to load all blueprints from the blueprints/ directory" do
      expect(blueprints.size).to eq(5)
      expect(blueprints.map(&:name)).to contain_exactly(
        "auth",
        "users/crud",
        "users/search",
        "setup",
        "posts"
      )
    end

    it "is expected to convert blueprints to Blueprint objects" do
      expect(blueprints).to all(be_a(SpecForge::Blueprint))
    end

    it "is expected to set correct file metadata" do
      auth = blueprints.find { |b| b.name == "auth" }
      expect(auth.file_path).to eq(Pathname.new("auth.yml"))
      expect(auth.file_name).to eq("auth.yml")

      user_crud = blueprints.find { |b| b.name == "users/crud" }
      expect(user_crud.file_path).to eq(Pathname.new("users/crud.yml"))
      expect(user_crud.file_name).to eq("crud.yml")
    end

    it "is expected to process steps through StepProcessor" do
      auth = blueprints.find { |b| b.name == "auth" }

      expect(auth.steps.size).to eq(2)
      expect(auth.steps.map(&:name)).to eq(["Login as admin", "Verify admin token"])

      # Steps should have source metadata
      expect(auth.steps[0].source.file_name).to eq("auth")
      expect(auth.steps[0].source.line_number).to be_a(Integer)
    end
  end

  describe "paths parameter" do
    context "when paths targets specific files" do
      let(:paths) { [fixtures_path.join("loader", "blueprints", "auth.yml")] }

      it "is expected to load only the specified blueprints" do
        expect(blueprints.size).to eq(1)
        expect(blueprints[0].name).to eq("auth")
      end
    end

    context "when paths targets multiple specific files" do
      let(:paths) do
        [
          fixtures_path.join("loader", "blueprints", "auth.yml"),
          fixtures_path.join("loader", "blueprints", "posts.yml")
        ]
      end

      it "is expected to load all specified blueprints" do
        expect(blueprints.size).to eq(2)
        expect(blueprints.map(&:name)).to contain_exactly("auth", "posts")
      end
    end

    context "when paths includes files that reference each other via include" do
      let(:paths) do
        [
          fixtures_path.join("loader", "blueprints", "auth.yml"),
          fixtures_path.join("loader", "blueprints", "setup.yml")
        ]
      end

      it "is expected to resolve includes between loaded files" do
        setup = blueprints.find { |b| b.name == "setup" }

        # setup includes auth, so should have auth steps expanded
        expect(setup.steps.size).to eq(4)
        expect(setup.steps[0].name).to eq("Login as admin")
      end
    end
  end

  describe "base_path parameter" do
    context "when base_path targets a subdirectory" do
      let(:base_path) { fixtures_path.join("loader", "blueprints", "users") }

      it "is expected to load only blueprints in that directory" do
        expect(blueprints.size).to eq(2)
        expect(blueprints.map(&:name)).to contain_exactly("crud", "search")
      end
    end
  end

  describe "tag filtering" do
    context "when filtering by tags" do
      let(:tags) { ["read"] }

      it "is expected to filter steps by tag" do
        user_crud = blueprints.find { |b| b.name == "users/crud" }
        user_search = blueprints.find { |b| b.name == "users/search" }
        posts = blueprints.find { |b| b.name == "posts" }

        expect(user_crud.steps.size).to eq(1)
        expect(user_crud.steps[0].name).to eq("Get user")

        expect(user_search.steps.size).to eq(2)

        expect(posts.steps.size).to eq(2)
        expect(posts.steps.map(&:name)).to contain_exactly("List posts", "Get post details")
      end

      it "is expected to remove blueprints with no matching steps" do
        expect(blueprints.none? { |b| b.name == "auth" }).to be true
      end
    end

    context "when filtering by skip_tags" do
      let(:skip_tags) { ["write"] }

      it "is expected to exclude steps with skip tags" do
        user_crud = blueprints.find { |b| b.name == "users/crud" }
        posts = blueprints.find { |b| b.name == "posts" }

        expect(user_crud.steps.size).to eq(1)
        expect(user_crud.steps[0].name).to eq("Get user")

        expect(posts.steps.size).to eq(2)
        expect(posts.steps.map(&:name)).to contain_exactly("List posts", "Get post details")
      end
    end

    context "when using both tags and skip_tags" do
      let(:tags) { ["users"] }
      let(:skip_tags) { ["write"] }

      it "is expected to apply both filters" do
        expect(blueprints.size).to eq(3)
        expect(blueprints.map(&:name)).to contain_exactly("users/crud", "users/search", "setup")

        user_crud = blueprints.find { |b| b.name == "users/crud" }
        expect(user_crud.steps.size).to eq(1)
        expect(user_crud.steps[0].name).to eq("Get user")

        # setup has "Create test users" which matches "users" tag and doesn't have "write"
        setup = blueprints.find { |b| b.name == "setup" }
        expect(setup.steps.size).to eq(1)
        expect(setup.steps[0].name).to eq("Create test users")
      end
    end
  end

  describe "combined filtering" do
    context "with base_path and tag filters" do
      let(:base_path) { fixtures_path.join("loader", "blueprints", "users") }
      let(:tags) { ["crud"] }

      it "is expected to apply both filters" do
        expect(blueprints.size).to eq(1)
        expect(blueprints[0].name).to eq("crud")
        expect(blueprints[0].steps.size).to eq(4)
      end
    end

    context "with all filters combined" do
      let(:base_path) { fixtures_path.join("loader", "blueprints", "users") }
      let(:tags) { ["crud"] }
      let(:skip_tags) { ["write"] }

      it "is expected to apply all filters in order" do
        expect(blueprints.size).to eq(1)
        expect(blueprints[0].name).to eq("crud")
        expect(blueprints[0].steps.size).to eq(1)
        expect(blueprints[0].steps[0].name).to eq("Get user")
      end
    end
  end

  describe "step processing integration" do
    context "when blueprints use includes" do
      it "is expected to expand includes" do
        setup = blueprints.find { |b| b.name == "setup" }

        # First step includes auth.yml (2 steps)
        # Second step has nested steps (2 steps)
        # Total: 4 steps after flattening (parent steps removed)
        expect(setup.steps.size).to eq(4)

        # Auth steps from include
        expect(setup.steps[0].name).to eq("Login as admin")
        expect(setup.steps[1].name).to eq("Verify admin token")

        # Nested steps
        expect(setup.steps[2].name).to eq("Create test users")
        expect(setup.steps[3].name).to eq("Create test posts")
      end

      it "is expected to apply tags from parent to included steps" do
        setup = blueprints.find { |b| b.name == "setup" }

        # Auth steps should inherit setup tags
        expect(setup.steps[0].tags).to include("setup", "auth")
        expect(setup.steps[1].tags).to include("setup", "auth")
      end
    end

    context "when blueprints use nested steps" do
      it "is expected to flatten nested steps" do
        setup = blueprints.find { |b| b.name == "setup" }

        # All steps should be flattened (no hierarchy)
        setup.steps.each do |step|
          expect(step).to be_a(SpecForge::Step)
          expect(step).not_to respond_to(:steps)
        end
      end

      it "is expected to inherit tags from parent steps" do
        setup = blueprints.find { |b| b.name == "setup" }

        # Nested steps should inherit parent tags
        create_users = setup.steps.find { |s| s.name == "Create test users" }
        expect(create_users.tags).to include("setup", "data", "users")
      end
    end
  end

  describe "line number injection" do
    subject(:loader) { described_class.new }

    let(:parsed_steps) { loader.send(:parse_steps, yaml_content) }

    context "with a simple step" do
      let(:yaml_content) do
        <<~YAML
          - name: "Test step"
            request:
              method: GET
              url: "/api/test"
        YAML
      end

      it "injects line_number on the step itself" do
        expect(parsed_steps[0][:line_number]).to eq(1)
      end

      it "does not inject line_number on the request hash" do
        expect(parsed_steps[0][:request]).not_to have_key(:line_number)
      end
    end

    context "with expect hash" do
      let(:yaml_content) do
        <<~YAML
          - name: "Test with expect"
            request:
              method: GET
              url: "/api/test"
            expect:
              status: 200
              json:
                content:
                  id: 1
        YAML
      end

      it "injects line_number on the step" do
        expect(parsed_steps[0][:line_number]).to eq(1)
      end

      it "does not inject line_number on expect hash" do
        expect(parsed_steps[0][:expect]).not_to have_key(:line_number)
      end

      it "does not inject line_number on nested expect hashes" do
        expect(parsed_steps[0][:expect][:json]).not_to have_key(:line_number)
        expect(parsed_steps[0][:expect][:json][:content]).not_to have_key(:line_number)
      end
    end

    context "with nested steps" do
      let(:yaml_content) do
        <<~YAML
          - name: "Parent step"
            request:
              method: GET
              url: "/api/parent"
            steps:
              - name: "Child step 1"
                request:
                  method: POST
                  url: "/api/child1"
              - name: "Child step 2"
                request:
                  method: PUT
                  url: "/api/child2"
        YAML
      end

      it "injects line_number on the parent step" do
        expect(parsed_steps[0][:line_number]).to eq(1)
      end

      it "injects line_number on each substep" do
        expect(parsed_steps[0][:steps][0][:line_number]).to eq(6)
        expect(parsed_steps[0][:steps][1][:line_number]).to eq(10)
      end

      it "does not inject line_number on request hashes within substeps" do
        expect(parsed_steps[0][:steps][0][:request]).not_to have_key(:line_number)
        expect(parsed_steps[0][:steps][1][:request]).not_to have_key(:line_number)
      end
    end

    context "with deeply nested steps" do
      let(:yaml_content) do
        <<~YAML
          - name: "Grandparent"
            steps:
              - name: "Parent"
                steps:
                  - name: "Child"
                    request:
                      method: GET
                      url: "/api/nested"
                    expect:
                      status: 200
        YAML
      end

      it "injects line_number at all step levels" do
        expect(parsed_steps[0][:line_number]).to eq(1)
        expect(parsed_steps[0][:steps][0][:line_number]).to eq(3)
        expect(parsed_steps[0][:steps][0][:steps][0][:line_number]).to eq(5)
      end

      it "does not inject line_number on non-step hashes at any level" do
        child = parsed_steps[0][:steps][0][:steps][0]
        expect(child[:request]).not_to have_key(:line_number)
        expect(child[:expect]).not_to have_key(:line_number)
      end
    end
  end
end
