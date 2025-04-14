# frozen_string_literal: true

# This is more for organizational purposes
RSpec.describe SpecForge::Normalizer do
  describe ".normalize_openapi_config!" do
    let(:config) do
      {
        info: {
          title: "My API",
          version: "1.0.0",
          description: "My API description",
          contact: {name: "My API Team", email: "api@example.com"},
          license: {name: "MIT", url: "https://opensource.org/licenses/MIT"}
        },
        servers: [{url: "http://localhost:3000", description: "Test"}],
        tags: {tag_1: "Tag 1"},
        security_schemes: {
          bearer_auth: {}
        }
      }
    end

    subject(:normalized) { described_class.normalize_openapi_config!(config) }

    it "is expected to normalize fully" do
      expect(normalized[:info]).to be_kind_of(Hash)
      expect(normalized[:info][:title]).to eq(config.dig(:info, :title))
      expect(normalized[:info][:version]).to eq(config.dig(:info, :version))
      expect(normalized[:info][:description]).to eq(config.dig(:info, :description))
      expect(normalized[:info][:contact]).to be_kind_of(Hash)
      expect(normalized[:info][:contact][:name]).to eq(config.dig(:info, :contact, :name))
      expect(normalized[:info][:contact][:email]).to eq(config.dig(:info, :contact, :email))
      expect(normalized[:info][:license]).to be_kind_of(Hash)
      expect(normalized[:info][:license][:name]).to eq(config.dig(:info, :license, :name))
      expect(normalized[:info][:license][:url]).to eq(config.dig(:info, :license, :url))

      expect(normalized[:servers]).to be_kind_of(Array)
      expect(normalized[:servers].first).to eq(config.dig(:servers, 0))
      expect(normalized[:tags]).to be_kind_of(Hash)
      expect(normalized[:security_schemes]).to be_kind_of(Hash)
    end

    context "when 'info' is nil" do
      before { config[:info] = nil }

      include_examples("raises_invalid_structure_error") do
        let(:error_messages) do
          [
            "Expected String, got NilClass for \"title\" in \"info\" in openapi/config/openapi.yml",
            "Expected String, got NilClass for \"version\" in \"info\" in openapi/config/openapi.yml"
          ]
        end
      end
    end

    context "when 'info' is not a Hash" do
      before { config[:info] = 1 }

      include_examples("raises_invalid_structure_error") do
        let(:error_message) do
          "Expected Hash, got Integer for \"info\" in openapi/config/openapi.yml"
        end
      end
    end

    context "when 'info.title' is nil" do
      before { config[:info][:title] = nil }

      include_examples("raises_invalid_structure_error") do
        let(:error_message) do
          "Expected String, got NilClass for \"title\" in \"info\" in openapi/config/openapi.yml"
        end
      end
    end

    context "when 'info.title' is not a String" do
      before { config[:info][:title] = 1 }

      include_examples("raises_invalid_structure_error") do
        let(:error_message) do
          "Expected String, got Integer for \"title\" in \"info\" in openapi/config/openapi.yml"
        end
      end
    end

    context "when 'info.version' is nil" do
      before { config[:info][:version] = nil }

      include_examples("raises_invalid_structure_error") do
        let(:error_message) do
          "Expected String, got NilClass for \"version\" in \"info\" in openapi/config/openapi.yml"
        end
      end
    end

    context "when 'info.version' is not a String" do
      before { config[:info][:version] = 1 }

      include_examples("raises_invalid_structure_error") do
        let(:error_message) do
          "Expected String, got Integer for \"version\" in \"info\" in openapi/config/openapi.yml"
        end
      end
    end

    context "when the bare minimum is given" do
      let(:config) do
        {info: {title: "", version: ""}}
      end

      it "is expected to normalize" do
        expect(normalized[:info]).to be_kind_of(Hash)
        expect(normalized[:info][:contact]).to be_kind_of(Hash)
        expect(normalized[:info][:license]).to be_kind_of(Hash)

        expect(normalized[:servers]).to be_kind_of(Array)
        expect(normalized[:tags]).to be_kind_of(Hash)
        expect(normalized[:security_schemes]).to be_kind_of(Hash)
      end
    end
  end
end
