# frozen_string_literal: true

RSpec.describe SpecForge::Forge do
  let(:blueprints) do
    SpecForge::Loader.new(
      base_path: fixtures_path.join("blueprints", "forge")
    ).load
  end

  subject(:forge) { described_class.new(blueprints) }

  it "test" do
    forge.run
    binding.pry
  end
end
