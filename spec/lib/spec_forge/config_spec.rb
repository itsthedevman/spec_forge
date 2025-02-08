# frozen_string_literal: true

RSpec.describe SpecForge::Config do
  describe "#initialize" do
    describe "when the configuration file exists" do
      let(:forge_path) { SpecForge.forge.join("config.yml") }
      let(:config) { described_class.new }

      let(:yaml_content) do
        <<~YAML
          base_url: <%= "http://localhost:3001" %>
        YAML
      end

      before do
        # Mock File.exist?
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(forge_path).and_return(true)

        # Mock File.read
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with(forge_path).and_return(yaml_content)
      end

      it "is expecting to parse, load, and overwrite the defaults" do
        expect(config.base_url).to eq("http://localhost:3001")
      end

      it "converts attributes to Data" do
        expect(config.authorization).to be_kind_of(Data)
        expect(config.authorization.default).to be_kind_of(SpecForge::Config::Authorization)
        expect(config.factories).to be_kind_of(SpecForge::Config::Factories)
      end
    end
  end
end
