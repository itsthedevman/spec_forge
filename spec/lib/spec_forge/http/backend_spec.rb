# frozen_string_literal: true

RSpec.describe SpecForge::HTTP::Backend do
  subject(:backend) { described_class.new }

  describe "#initialize" do
    it "creates a Faraday connection" do
      expect(backend.connection).to be_a(Faraday::Connection)
    end
  end

  describe "HTTP methods" do
    let(:base_url) { "http://example.com" }
    let(:url) { "/api/test" }
    let(:headers) { {"X-Custom-Header" => "value"} }
    let(:query) { {page: 1, limit: 10} }
    let(:body) { {name: "test"} }

    let(:stubs) { Faraday::Adapter::Test::Stubs.new }
    let(:test_connection) do
      Faraday.new do |builder|
        builder.adapter :test, stubs
      end
    end

    before do
      allow(Faraday).to receive(:new).and_return(test_connection)
    end

    after do
      stubs.verify_stubbed_calls
    end

    describe "#get" do
      it "sends a GET request with the correct parameters" do
        stubs.get("/api/test") do |env|
          expect(env.params).to eq({"page" => "1", "limit" => "10"})
          expect(env.request_headers["X-Custom-Header"]).to eq("value")
          [200, {}, "success"]
        end

        response = backend.get(url: url, base_url:, headers:, query:)
        expect(response.status).to eq(200)
        expect(response.body).to eq("success")
      end

      it "works with minimal parameters" do
        stubs.get("/simple") do |env|
          expect(env.url.to_s).to eq("http://example.com/simple")
          [200, {}, "ok"]
        end

        response = backend.get(url: "/simple", base_url:)
        expect(response.status).to eq(200)
      end
    end

    describe "#post" do
      it "sends a POST request with body" do
        stubs.post("/api/test") do |env|
          expect(env.url.to_s).to eq("http://example.com/api/test")
          expect(env.body).to eq(body)
          [201, {}, "created"]
        end

        response = backend.post(url: url, base_url:, body:)
        expect(response.status).to eq(201)
      end
    end

    describe "#put" do
      it "sends a PUT request with body" do
        stubs.put("/api/test") do |env|
          expect(env.body).to eq(body)
          [200, {}, "updated"]
        end

        response = backend.put(url: url, base_url:, body:)
        expect(response.status).to eq(200)
      end
    end

    describe "#patch" do
      it "sends a PATCH request with body" do
        stubs.patch("/api/test") do |env|
          expect(env.body).to eq(body)
          [200, {}, "patched"]
        end

        response = backend.patch(url: url, base_url:, body:)
        expect(response.status).to eq(200)
      end
    end

    describe "#delete" do
      it "sends a DELETE request" do
        stubs.delete("/api/test") do |env|
          expect(env.url.to_s).to eq("http://example.com/api/test")
          [204, {}, ""]
        end

        response = backend.delete(url:, base_url:)
        expect(response.status).to eq(204)
      end
    end

    describe "header transformation" do
      it "converts header values to strings" do
        stubs.get("/api/test") do |env|
          expect(env.request_headers["X-Numeric"]).to eq("123")
          [200, {}, "ok"]
        end

        backend.get(url:, base_url:, headers: {"X-Numeric" => 123})
      end
    end
  end
end
