# frozen_string_literal: true

RSpec.describe SpecForge::Forge do
  let(:blueprints) do
    SpecForge::Loader.new(
      base_path: fixtures_path.join("blueprints", "forge")
    ).load
  end

  subject(:forge) { described_class.new(blueprints) }

  before do
    forge.callbacks.register_callback(:setup_database) {}
    forge.callbacks.register_callback(:cleanup_database) {}
    forge.callbacks.register_callback(:initialize_tests) {}
    forge.callbacks.register_callback(:seed_data) {}
  end

  it "test" do
    forge.run
    binding.pry
  end
end
