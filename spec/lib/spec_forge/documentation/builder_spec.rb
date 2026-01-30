# frozen_string_literal: true

require_relative "../../../support/discord_api"

RSpec.describe SpecForge::Documentation::Builder, :integration do
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
  end

  let(:paths) { fixtures_path.join("blueprints", "forge", "discord_api.yml") }

  describe "#endpoints" do
    subject(:builder) { described_class.new(paths: paths) }

    it "returns an array of endpoint data" do
      expect(builder.endpoints).to be_an(Array)
    end

    it "captures endpoints from successful blueprint runs" do
      endpoints = builder.endpoints

      expect(endpoints).not_to be_empty
    end

    it "extracts endpoint data with required keys" do
      endpoint = builder.endpoints.first

      expect(endpoint).to include(
        :base_url,
        :url,
        :http_verb,
        :content_type,
        :request_body,
        :request_headers,
        :request_query,
        :response_status,
        :response_body,
        :response_headers
      )
    end

    it "captures different HTTP methods" do
      endpoints = builder.endpoints
      http_verbs = endpoints.map { |e| e[:http_verb] }.uniq

      expect(http_verbs).to include("GET", "POST", "PATCH", "DELETE")
    end

    it "captures both success and error responses" do
      endpoints = builder.endpoints
      statuses = endpoints.map { |e| e[:response_status] }.uniq

      expect(statuses).to include(200, 201, 401, 403, 404)
    end
  end

  describe ".create_document!" do
    it "returns a Document object" do
      document = described_class.create_document!(paths: paths)

      expect(document).to be_a(SpecForge::Documentation::Document)
    end

    it "contains endpoints grouped by URL path" do
      document = described_class.create_document!(paths: paths)

      expect(document.endpoints.keys).not_to be_empty
      expect(document.endpoints.keys.map(&:to_s)).to all(start_with("/api/v10/"))
    end
  end
end
