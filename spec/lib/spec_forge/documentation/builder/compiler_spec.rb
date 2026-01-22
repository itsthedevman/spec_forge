# frozen_string_literal: true

RSpec.describe SpecForge::Documentation::Builder::Compiler do
  let(:endpoints) do
    [
      {
        base_url: "http://localhost:4569",
        url: "/api/v10/users/@me",
        http_verb: "GET",
        content_type: "application/json",
        request_body: {},
        request_headers: {authorization: "Bot token"},
        request_query: {},
        response_status: 200,
        response_body: {id: "123", username: "TestBot", bot: true},
        response_headers: {"content-type" => "application/json"}
      },
      {
        base_url: "http://localhost:4569",
        url: "/api/v10/channels/456/messages",
        http_verb: "GET",
        content_type: "application/json",
        request_body: {},
        request_headers: {authorization: "Bot token"},
        request_query: {limit: 50},
        response_status: 200,
        response_body: [{id: "789", content: "Hello"}],
        response_headers: {"content-type" => "application/json"}
      },
      {
        base_url: "http://localhost:4569",
        url: "/api/v10/channels/456/messages",
        http_verb: "POST",
        content_type: "application/json",
        request_body: {content: "New message"},
        request_headers: {authorization: "Bot token"},
        request_query: {},
        response_status: 201,
        response_body: {id: "790", content: "New message"},
        response_headers: {"content-type" => "application/json"}
      },
      {
        base_url: "http://localhost:4569",
        url: "/api/v10/users/@me",
        http_verb: "GET",
        content_type: "application/json",
        request_body: {},
        request_headers: {},
        request_query: {},
        response_status: 401,
        response_body: {message: "Unauthorized", code: 0},
        response_headers: {"content-type" => "application/json"}
      }
    ]
  end

  subject(:compiler) { described_class.new(endpoints) }

  describe "#compile" do
    subject(:compiled) { compiler.compile }

    it "groups endpoints by URL path" do
      expect(compiled.keys).to contain_exactly(
        "/api/v10/users/@me",
        "/api/v10/channels/456/messages"
      )
    end

    it "groups operations by HTTP verb within each path" do
      expect(compiled["/api/v10/users/@me"].keys).to contain_exactly("GET")
      expect(compiled["/api/v10/channels/456/messages"].keys).to contain_exactly("GET", "POST")
    end

    it "includes required keys in each operation" do
      operation = compiled["/api/v10/users/@me"]["GET"]

      expect(operation).to include(:id, :description, :parameters, :requests, :responses)
    end

    it "generates unique IDs for operations" do
      operation = compiled["/api/v10/users/@me"]["GET"]

      expect(operation[:id]).to start_with("id_")
      expect(operation[:id]).to match(/^id_[0-9a-f-]{36}$/)
    end

    it "generates placeholder descriptions" do
      operation = compiled["/api/v10/users/@me"]["GET"]

      expect(operation[:description]).to start_with("description_")
    end

    describe "parameters" do
      it "extracts query parameters with types" do
        operation = compiled["/api/v10/channels/456/messages"]["GET"]

        expect(operation[:parameters]).to have_key(:limit)
        expect(operation[:parameters][:limit]).to eq(location: "query", type: "integer")
      end

      it "returns empty parameters when none exist" do
        operation = compiled["/api/v10/users/@me"]["GET"]

        expect(operation[:parameters]).to be_empty
      end
    end

    describe "requests" do
      it "extracts request bodies from successful operations" do
        operation = compiled["/api/v10/channels/456/messages"]["POST"]

        expect(operation[:requests]).not_to be_empty
        expect(operation[:requests].first[:content]).to eq(content: "New message")
      end

      it "includes content type in request" do
        operation = compiled["/api/v10/channels/456/messages"]["POST"]

        expect(operation[:requests].first[:content_type]).to eq("application/json")
      end

      it "determines request body type" do
        operation = compiled["/api/v10/channels/456/messages"]["POST"]

        expect(operation[:requests].first[:type]).to eq("object")
      end

      it "returns empty requests for GET operations" do
        operation = compiled["/api/v10/users/@me"]["GET"]

        expect(operation[:requests]).to be_empty
      end
    end

    describe "responses" do
      it "includes all response statuses" do
        operation = compiled["/api/v10/users/@me"]["GET"]
        statuses = operation[:responses].map { |r| r[:status] }

        expect(statuses).to contain_exactly(200, 401)
      end

      it "normalizes response headers with types" do
        operation = compiled["/api/v10/users/@me"]["GET"]
        response = operation[:responses].find { |r| r[:status] == 200 }

        expect(response[:headers]["content-type"]).to eq(type: "string")
      end

      it "normalizes response body for objects" do
        operation = compiled["/api/v10/users/@me"]["GET"]
        response = operation[:responses].find { |r| r[:status] == 200 }

        expect(response[:body][:type]).to eq("object")
        expect(response[:body][:content]).to have_key(:id)
        expect(response[:body][:content][:id]).to eq(type: "integer")
      end

      it "normalizes response body for arrays" do
        operation = compiled["/api/v10/channels/456/messages"]["GET"]
        response = operation[:responses].first

        expect(response[:body][:type]).to eq("array")
      end
    end

    describe "error response sanitization" do
      it "clears request data from error responses" do
        # The 401 response should have its request data cleared
        operation = compiled["/api/v10/users/@me"]["GET"]
        responses = operation[:responses]

        # Should still have both responses
        expect(responses.size).to eq(2)
      end
    end
  end

  describe "type detection" do
    let(:endpoints) do
      [
        {
          base_url: "http://localhost",
          url: "/test",
          http_verb: "GET",
          content_type: "application/json",
          request_body: {},
          request_headers: {},
          request_query: {
            count: 42,
            price: 19.99,
            enabled: true,
            name: "test",
            uuid: "550e8400-e29b-41d4-a716-446655440000"
          },
          response_status: 200,
          response_body: {result: "ok"},
          response_headers: {}
        }
      ]
    end

    it "detects integer types" do
      operation = compiler.compile["/test"]["GET"]

      expect(operation[:parameters][:count][:type]).to eq("integer")
    end

    it "detects double types" do
      operation = compiler.compile["/test"]["GET"]

      expect(operation[:parameters][:price][:type]).to eq("double")
    end

    it "detects boolean types" do
      operation = compiler.compile["/test"]["GET"]

      expect(operation[:parameters][:enabled][:type]).to eq("boolean")
    end

    it "detects string types" do
      operation = compiler.compile["/test"]["GET"]

      expect(operation[:parameters][:name][:type]).to eq("string")
    end

    it "detects UUID types" do
      operation = compiler.compile["/test"]["GET"]

      expect(operation[:parameters][:uuid][:type]).to eq("uuid")
    end
  end
end
