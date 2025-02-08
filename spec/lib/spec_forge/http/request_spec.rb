# frozen_string_literal: true

RSpec.describe SpecForge::HTTP::Request do
  let(:base_url) {}
  let(:url) { "/users" }
  let(:method) {}
  let(:content_type) {}
  let(:query) {}
  let(:body) {}
  let(:authorization) {}
  let(:variables) {}

  let(:options) do
    result, _errors = SpecForge::Normalizer.normalize_expectations(
      [{url:, method:, content_type:, query:, body:}]
    )

    SpecForge::Attribute.from(result.first.merge(base_url:, authorization:, variables:))
  end

  subject(:request) { described_class.new(**options) }

  describe "#initialize" do
    it "defaults content_type to application/json" do
      expect(request.content_type).to be_kind_of(MIME::Type)
      expect(request.content_type).to eq("application/json")
    end

    it "defaults http_method to GET" do
      expect(request.http_method).to be_kind_of(SpecForge::HTTP::Verb::Get)
    end

    context "when 'base_url' is provided" do
      let(:base_url) { "http://example.com" }

      it "is expected to use it" do
        expect(request.base_url).to eq(base_url)
      end
    end

    context "when 'base_url' is not provided" do
      it "is expected to use the global default" do
        expect(request.base_url).to eq(SpecForge.config.base_url)
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

    context "when 'content_type' is not a valid MIME type" do
      let(:content_type) { "in/valid" }

      it { expect { request }.to raise_error(ArgumentError) }
    end

    context "when 'http_method' is mixed case" do
      let(:method) { "DeLeTe" }

      it "works because it is case insensitive" do
        expect(request.http_method).to eq("DELETE")
      end
    end

    context "when 'authorization' is provided" do
      let(:authorization) { :not_supported_yet }

      it "uses the default config" do
        expect(request.authorization).to have_attributes(
          header: be_kind_of(String), value: be_kind_of(String)
        )
      end
    end

    context "when 'authorization' is not provided" do
      it "uses the default config" do
        expect(request.authorization).to have_attributes(
          header: be_kind_of(String), value: be_kind_of(String)
        )
      end
    end
  end
end
