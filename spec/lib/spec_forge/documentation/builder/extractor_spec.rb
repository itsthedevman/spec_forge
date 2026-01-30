# frozen_string_literal: true

RSpec.describe SpecForge::Documentation::Builder::Extractor do
  let(:step) { instance_double(SpecForge::Step) }
  let(:variables) do
    {
      request: {
        base_url: "http://localhost:4569",
        url: "/api/v10/users/@me",
        http_verb: "GET",
        headers: {
          "content-type" => "application/json",
          "authorization" => "Bot token123"
        },
        body: {},
        query: {limit: 50}
      },
      response: {
        status: 200,
        body: {id: "123", username: "TestBot"},
        headers: {"content-type" => "application/json"}
      }
    }
  end

  let(:context) do
    instance_double(
      SpecForge::Forge::Context,
      step: step,
      variables: variables
    )
  end

  subject(:extractor) { described_class.new(context) }

  describe "#extract_endpoint" do
    subject(:endpoint) { extractor.extract_endpoint }

    it "extracts the base URL" do
      expect(endpoint[:base_url]).to eq("http://localhost:4569")
    end

    it "extracts the URL path" do
      expect(endpoint[:url]).to eq("/api/v10/users/@me")
    end

    it "extracts the HTTP verb" do
      expect(endpoint[:http_verb]).to eq("GET")
    end

    it "extracts the content type from headers" do
      expect(endpoint[:content_type]).to eq("application/json")
    end

    it "extracts request headers without content-type" do
      expect(endpoint[:request_headers]).to eq("authorization" => "Bot token123")
      expect(endpoint[:request_headers]).not_to have_key("content-type")
    end

    it "extracts the request body" do
      expect(endpoint[:request_body]).to eq({})
    end

    it "extracts the request query parameters" do
      expect(endpoint[:request_query]).to eq(limit: 50)
    end

    it "extracts the response status" do
      expect(endpoint[:response_status]).to eq(200)
    end

    it "extracts the response body" do
      expect(endpoint[:response_body]).to eq(id: "123", username: "TestBot")
    end

    it "extracts the response headers" do
      expect(endpoint[:response_headers]).to eq("content-type" => "application/json")
    end
  end

  context "with POST request containing a body" do
    let(:variables) do
      {
        request: {
          base_url: "http://localhost:4569",
          url: "/api/v10/channels/123/messages",
          http_verb: "POST",
          headers: {
            "content-type" => "application/json",
            "authorization" => "Bot token123"
          },
          body: {content: "Hello, world!"},
          query: {}
        },
        response: {
          status: 201,
          body: {id: "456", content: "Hello, world!"},
          headers: {"content-type" => "application/json"}
        }
      }
    end

    it "extracts the request body" do
      endpoint = extractor.extract_endpoint

      expect(endpoint[:request_body]).to eq(content: "Hello, world!")
    end

    it "extracts the 201 status" do
      endpoint = extractor.extract_endpoint

      expect(endpoint[:response_status]).to eq(201)
    end
  end
end
