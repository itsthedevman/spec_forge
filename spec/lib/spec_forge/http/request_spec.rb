# frozen_string_literal: true

RSpec.describe SpecForge::HTTP::Request do
  let(:base_url) { "http://localhost:3000" }
  let(:url) { "/users" }
  let(:http_verb) { "GET" }
  let(:headers) { {} }
  let(:query) { {} }
  let(:body) { {} }

  let(:options) do
    {base_url:, url:, http_verb:, headers:, query:, body:}
  end

  subject(:request) { described_class.new(**options) }

  describe "#initialize" do
    it "defaults http_verb to GET" do
      expect(request.http_verb).to be_kind_of(SpecForge::HTTP::Verb::Get)
    end

    it "defaults base_url to empty string" do
      request = described_class.new(url: "/test")
      expect(request.base_url).to eq("")
    end

    it "defaults url to empty string" do
      request = described_class.new
      expect(request.url).to eq("")
    end

    it "defaults headers to empty hash" do
      request = described_class.new
      expect(request.headers).to eq({})
    end

    it "defaults query to empty hash" do
      request = described_class.new
      expect(request.query).to eq({})
    end

    it "defaults body to empty hash" do
      request = described_class.new
      expect(request.body).to eq({})
    end

    context "when 'headers' are provided" do
      let(:headers) { {"content-type" => "application/json", "Authorization" => "Bearer token"} }

      it "stores headers as provided" do
        expect(request.headers).to eq(headers)
      end
    end

    context "when 'base_url' is provided" do
      it "uses the provided base_url" do
        expect(request.base_url).to eq(base_url)
      end
    end

    context "when 'query' is provided" do
      let(:query) { {filter: "active", page: 1} }

      it "stores query params as provided" do
        expect(request.query).to eq(query)
      end
    end

    context "when 'http_verb' is mixed case" do
      let(:http_verb) { "DeLeTe" }

      it "works because Verb.from is case insensitive" do
        expect(request.http_verb).to eq("DELETE")
      end
    end

    context "when 'body' is provided" do
      let(:body) { {name: "Test User", age: 25} }

      it "stores body as provided" do
        expect(request.body).to eq(body)
      end
    end
  end

  describe "#content_type" do
    context "when content-type header is set" do
      let(:headers) { {"content-type" => "application/json"} }

      it "returns the content type" do
        expect(request.content_type).to eq("application/json")
      end
    end

    context "when content-type header is not set" do
      it "returns nil" do
        expect(request.content_type).to be_nil
      end
    end
  end

  describe "#json?" do
    context "when content type is application/json" do
      let(:headers) { {"content-type" => "application/json"} }

      it "returns true" do
        expect(request.json?).to be(true)
      end
    end

    context "when content type is not application/json" do
      let(:headers) { {"content-type" => "text/plain"} }

      it "returns false" do
        expect(request.json?).to be(false)
      end
    end

    context "when content type is not set" do
      it "returns false" do
        expect(request.json?).to be(false)
      end
    end
  end

  describe "#to_h" do
    let(:headers) { {"content-type" => "application/json"} }
    let(:body) { {name: "Test"} }

    it "returns a hash representation" do
      expect(request.to_h).to be_a(Hash)
    end

    it "converts http_verb to string" do
      expect(request.to_h[:http_verb]).to eq("GET")
    end

    it "includes all attributes" do
      hash = request.to_h
      expect(hash).to include(
        base_url: base_url,
        url: url,
        http_verb: "GET",
        headers: headers,
        query: query,
        body: body
      )
    end
  end
end
