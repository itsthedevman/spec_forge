# frozen_string_literal: true

RSpec.describe SpecForge::Loader do
  let(:path) { "" }
  let(:tags) { [] }
  let(:skip_tags) { [] }

  subject(:loader) { described_class.new(path:, tags:, skip_tags:) }

  before do
    allow(SpecForge).to receive(:forge_path).and_return(fixtures_path.join("loader"))
  end

  it "is expected to load from the blueprints/ directory" do
    expect(loader.blueprints.size).to eq(3)

    blueprints_path = fixtures_path.join("loader", "blueprints")

    blueprint = loader.blueprints.first
    expect(blueprint.file_path).to eq(blueprints_path.join("00.yml"))
    expect(blueprint.file_name).to eq("00.yml")
    expect(blueprint.name).to eq("00")
    expect(blueprint.steps.size).to eq(1)
    expect(blueprint.steps.map(&:name)).to eq(["00 - Step 1"])

    blueprint = loader.blueprints.second
    expect(blueprint.file_path).to eq(blueprints_path.join("01.yml"))
    expect(blueprint.file_name).to eq("01.yml")
    expect(blueprint.name).to eq("01")
    expect(blueprint.steps.size).to eq(2)
    expect(blueprint.steps.map(&:name)).to eq(["01 - Step 1", "01 - Step 2"])

    blueprint = loader.blueprints.third
    expect(blueprint.file_path).to eq(blueprints_path.join("subdirectory", "02.yml"))
    expect(blueprint.file_name).to eq("02.yml")
    expect(blueprint.name).to eq("subdirectory/02")
    expect(blueprint.steps.size).to eq(3)
    expect(blueprint.steps.map(&:name)).to eq(["02 - Step 1", "02 - Step 2", "02 - Step 3"])
  end
end
