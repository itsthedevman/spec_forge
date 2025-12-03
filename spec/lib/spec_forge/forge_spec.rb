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
    forge.callbacks.register_callback(:log_request) {}
    forge.callbacks.register_callback(:set_context) {}
    forge.callbacks.register_callback(:verify_cleanup) {}
  end

  context "when the Configuration has callbacks defined" do
    before do
      SpecForge.configure do |config|
        config.register_callback(:my_global_callback) {}
        config.register_callback(:my_other_callback) {}
      end
    end

    it "is expected to register them with the forge" do
      forge.send(:load_from_configuration)

      expect(forge.callbacks.callback_registered?(:my_global_callback)).to be(true)
      expect(forge.callbacks.callback_registered?(:my_other_callback)).to be(true)
    end
  end

  context "when the Configuration has global variables defined" do
    before do
      SpecForge.configure do |config|
        config.global_variables[:my_global_variable] = "value"
      end
    end

    it "is expected to register them with the forge" do
      forge.send(:load_from_configuration)

      expect(forge.global_variables[:my_global_variable]).to eq("value")
    end
  end

  it "test" do
    forge.run
    binding.pry
  end
end
