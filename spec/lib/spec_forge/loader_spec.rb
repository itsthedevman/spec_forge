# frozen_string_literal: true

RSpec.describe SpecForge::Loader do
  let(:path) { "" }
  let(:tags) { [] }
  let(:skip_tags) { [] }

  subject(:loader) { described_class.new(path:, tags:, skip_tags:) }

  context "when no path is provided" do
    before do
      allow(SpecForge).to receive(:forge_path).and_return(fixtures_path.join("loader"))
    end

    it "is expected to load from the blueprints/ directory" do
      expect(loader.blueprints.size).to eq(2)

      blueprint = loader.blueprints.first
      expect(blueprint.base_path).to eq(fixtures_path.join("loader", "blueprints"))
      expect(blueprint.file_path).to eq(fixtures_path.join("loader", "blueprints", "00_alpha.yml"))
      expect(blueprint.file_name).to eq("00_alpha.yml")
      expect(blueprint.steps.size).to eq(3)

      blueprint = loader.blueprints.second
      expect(blueprint.base_path).to eq(fixtures_path.join("loader", "blueprints"))
      expect(blueprint.file_path).to eq(
        fixtures_path.join("loader", "blueprints", "subdirectory", "01_bravo.yml")
      )

      expect(blueprint.file_name).to eq("subdirectory/01_bravo.yml")
      expect(blueprint.steps.size).to eq(2)
    end
  end

  context "when a file path is provided" do
    let(:base_path) { fixtures_path.join("loader", "custom") }
    let(:path) { base_path.join("steps.yml") }

    it "is expected to load the provided file at path" do
      expect(loader.blueprints.size).to eq(1)

      blueprint = loader.blueprints.first
      expect(blueprint.base_path).to eq(base_path)
      expect(blueprint.file_path).to eq(path)
      expect(blueprint.file_name).to eq("steps.yml")
      expect(blueprint.steps.size).to eq(3)
    end
  end

  context "when a directory path is provided" do
  end

  context "when tags are provided"

  context "when skip_tags are provided"

  context "when both tags and skip_tags are provided"
end
