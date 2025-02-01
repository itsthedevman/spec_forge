# frozen_string_literal: true

RSpec.describe SpecForge::Configuration do
  describe "#load_from_file" do
    describe "when the configuration file exists" do
      let(:forge_path) { SpecForge.forge.join("config.yml") }

      let(:yaml_content) do
        <<~YAML
          require_name: <%= false %>
        YAML
      end

      before do
        # Mock File.exist?
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(forge_path).and_return(true)

        # Mock File.read
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(forge_path).and_return(yaml_content)

        SpecForge.config.load_from_file
      end

      it "is expecting to parse, load, and overwrite the defaults" do
        expect(SpecForge.config.require_name).to be(false)
      end
    end
  end
end
