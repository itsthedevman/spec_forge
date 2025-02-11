# frozen_string_literal: true

RSpec.describe SpecForge::Configuration do
  describe "#validate" do
    let(:base_url) { "http://localhost:3001" }

    let(:headers) do
      {
        "Authorization" => "Bearer Bear",
        :header_1 => "value_1"
      }
    end

    let(:query) do
      {
        query_1: "value_1"
      }
    end

    let(:factories) do
      {
        auto_discover: false,
        paths: ["some/path"]
      }
    end

    let(:config) do
      SpecForge.configure do |config|
        config.base_url = base_url
        config.headers = headers
        config.query = query
        config.factories = factories
      end
    end

    subject(:validated) { config.validate }

    it "validates successfully" do
      expect { validated }.not_to raise_error

      expect(config.base_url).to eq(base_url)
      expect(config.headers).to eq(headers)
      expect(config.query).to eq(query)
    end

    context "when 'base_url' is nil" do
      let(:base_url) { nil }

      it do
        expect { validated }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected String, got NilClass for \"base_url\" on configuration"
        )
      end
    end

    context "when 'base_url' is not a String" do
      let(:base_url) { 1 }

      it do
        expect { validated }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected String, got Integer for \"base_url\" on configuration"
        )
      end
    end

    context "when 'headers' is nil" do
      let(:headers) { nil }

      it do
        expect { validated }.not_to raise_error
        expect(config.headers).to eq({})
      end
    end

    context "when 'headers' is not a Hash" do
      let(:headers) { 1 }

      it do
        expect { validated }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected Hash, got Integer for \"headers\" on configuration"
        )
      end
    end

    context "when 'query' is nil" do
      let(:query) { nil }

      it do
        expect { validated }.not_to raise_error
        expect(config.query).to eq({})
      end
    end

    context "when 'query' is not a hash" do
      let(:query) { 1 }

      it do
        expect { validated }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected Hash, got Integer for \"query\" on configuration"
        )
      end
    end
  end
end
