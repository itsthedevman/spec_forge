# frozen_string_literal: true

RSpec.describe SpecForge::HTTP::Request do
  let(:base_url) { "http://localhost:3000" }
  let(:url) { "/users" }
  let(:method) {}
  let(:headers) {}
  let(:query) {}
  let(:body) {}
  let(:authorization) {}
  let(:variables) {}

  let(:options) do
    result = SpecForge::Normalizer.normalize_expectations!(
      [{url:, method:, headers:, query:, body:, expect: {status: 404}}]
    )

    SpecForge::Attribute.from(result.first.merge(base_url:, authorization:, variables:))
  end

  subject(:request) { described_class.new(**options) }

  describe "#initialize" do
    it "defaults http_verb to GET" do
      expect(request.http_verb).to be_kind_of(SpecForge::HTTP::Verb::Get)
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
      let(:variables) { {id: 1} }
      let(:query) { {id: "variables.id", filter: "faker.string.random"} }

      it "is expected to update any referenced variables" do
        expect(request.query[:id]).to be_kind_of(SpecForge::Attribute::Variable)
        expect(request.query[:id].value).to eq(variables[:id])
      end
    end

    context "when 'body' is provided" do
      let(:variables) { {id: 1} }
      let(:body) { {id: "variables.id", filter: "faker.string.random"} }

      it "is expected to update any referenced variables" do
        expect(request.body[:id]).to be_kind_of(SpecForge::Attribute::Variable)
        expect(request.body[:id].value).to eq(variables[:id])
      end
    end

    context "when 'http_verb' is mixed case" do
      let(:method) { "DeLeTe" }

      it "works because it is case insensitive" do
        expect(request.http_verb).to eq("DELETE")
      end
    end
  end
end
