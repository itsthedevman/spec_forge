# frozen_string_literal: true

require_relative "../../../../support/discord_api"

RSpec.describe SpecForge::Documentation::OpenAPI::V30, :integration do
  # Start API server in background thread
  before(:all) do
    @server_thread = Thread.new do
      DiscordAPI.run!(
        port: 4569,
        server: "webrick",
        logging: false,
        traps: false,
        server_settings: {
          Logger: WEBrick::Log.new(File::NULL),
          AccessLog: []
        }
      )
    end

    sleep 0.01
  end

  after(:all) do
    @server_thread&.kill
  end

  before do
    DiscordAPI.reset_data!
    SpecForge.configuration.base_url = "http://localhost:4569"

    # Silence display output
    allow_any_instance_of(SpecForge::Forge::Display).to receive(:puts)
    allow_any_instance_of(SpecForge::Forge::Display).to receive(:print)

    # Mock cache to prevent file writes
    allow_any_instance_of(SpecForge::Documentation::Builder::Cache).to receive(:valid?).and_return(false)
    allow_any_instance_of(SpecForge::Documentation::Builder::Cache).to receive(:create)

    # Mock config loading to return minimal valid config
    allow_any_instance_of(described_class).to receive(:config).and_return({
      "info" => {
        "title" => "Test API",
        "version" => "1.0.0"
      }
    })
  end

  let(:paths) { fixtures_path.join("blueprints", "forge", "discord_api.yml") }
  let(:document) { SpecForge::Documentation::Builder.create_document!(paths: paths) }
  subject(:generator) { described_class.new(document) }

  describe "#generate" do
    it "returns a hash with openapi version" do
      output = generator.generate

      expect(output["openapi"]).to eq("3.0.4")
      expect { described_class.validate!(output) }.not_to raise_error
    end
  end
end
