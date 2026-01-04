# frozen_string_literal: true

RSpec.describe SpecForge::Forge::Request do
  let(:step) do
    SpecForge::Step.new(
      name: "Make API request",
      source: {file_name: "test.yml", line_number: 15},
      request: {
        url: "/api/users",
        http_verb: "POST",
        json: {name: "Test User"}
      }
    )
  end

  let(:display) { instance_double(SpecForge::Forge::Display, action: nil) }
  let(:faraday_response) do
    double("Faraday::Response", to_h: {status: 200, body: {id: 1}})
  end
  let(:http_client) { instance_double(SpecForge::HTTP::Client, perform: faraday_response) }
  let(:variables) { {} }

  let(:forge) do
    instance_double(
      SpecForge::Forge,
      http_client:,
      variables:,
      display:
    )
  end

  subject(:action) { described_class.new(step) }

  describe "#run" do
    before do
      # Stub the configuration for base_url
      allow(SpecForge.configuration).to receive(:base_url).and_return("http://localhost:3000")
    end

    subject(:run) { action.run(forge) }

    it "displays the request action" do
      run

      expect(display).to have_received(:action).with(
        :request,
        "POST /api/users",
        color: :yellow
      )
    end

    it "performs the HTTP request" do
      run

      expect(http_client).to have_received(:perform)
    end

    it "stores the request in variables" do
      run

      expect(variables[:request]).to be_a(Hash)
      expect(variables[:request][:url]).to eq("/api/users")
    end

    it "stores the response in variables" do
      run

      expect(variables[:response]).to be_a(Hash)
      expect(variables[:response][:status]).to eq(200)
    end
  end
end
