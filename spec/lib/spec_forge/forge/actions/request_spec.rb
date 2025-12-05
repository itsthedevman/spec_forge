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
  let(:response) { instance_double(Faraday::Response, status: 200, body: {id: 1}) }
  let(:http_client) { instance_double(SpecForge::HTTP::Client, perform: response) }
  let(:local_variables) { instance_double(SpecForge::Forge::Store, store: nil) }

  let(:forge) do
    instance_double(
      SpecForge::Forge,
      http_client:,
      local_variables:,
      display:
    )
  end

  subject(:action) { described_class.new(step) }

  describe "#run" do
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

      expect(http_client).to have_received(:perform).with(step.request)
    end

    it "stores the request in local variables" do
      run

      expect(local_variables).to have_received(:store).with(:request, step.request)
    end

    it "stores the response in local variables" do
      run

      expect(local_variables).to have_received(:store).with(:response, response)
    end
  end
end
