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

    it "defaults content_type to \"application/json\"" do
      expect(request.content_type).to eq("application/json")
    end

    context "when 'headers' are provided" do
      let(:headers) { {:content_type => 1, "Custom-Header-2" => 2} }

      it "is expected to normalize if needed" do
        expect(request.headers).to eq("Content-Type" => 1, "Custom-Header-2" => 2)
      end
    end

    context "when 'base_url' is provided" do
      it "is expected to use it" do
        expect(request.base_url).to eq(base_url)
      end
    end

    context "when 'query' is provided" do
      let(:query) { {filter: "faker.string.random"} }

      it "is expected to convert to Attribute" do
        expect(request.query[:filter]).to be_kind_of(SpecForge::Attribute::Faker)
        expect(request.query[:filter].value).to be_kind_of(String)
      end
    end

    context "when 'body' is provided" do
      let(:body) { {filter: "faker.string.random"} }

      it "is expected to convert to Attribute" do
        expect(request.body[:filter]).to be_kind_of(SpecForge::Attribute::Faker)
        expect(request.body[:filter].value).to be_kind_of(String)
      end
    end

    context "when 'http_verb' is mixed case" do
      let(:http_verb) { "DeLeTe" }

      it "works because it is case insensitive" do
        expect(request.http_verb).to eq("DELETE")
      end
    end
  end
end
