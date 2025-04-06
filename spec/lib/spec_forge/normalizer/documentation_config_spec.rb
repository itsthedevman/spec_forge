# frozen_string_literal: true

# This is more for organizational purposes
RSpec.describe SpecForge::Normalizer do
  describe ".normalize_documentation_config!" do
    let(:config) do
      {
        info: {
          title: "My API",
          version: "1.0.0",
          description: "My API description",
          contact: {name: "My API Team", email: "api@example.com"},
          license: {name: "MIT", url: "https://opensource.org/licenses/MIT"}
        },
        openapi: {
          servers: [{url: "http://localhost:3000", description: "Test"}],
          tags: {tag_1: "Tag 1"},
          security_schemes: {
            bearer_auth: {}
          }
        }
      }
    end

    subject(:normalized) { described_class.normalize_documentation_config!(config) }

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

      expect(normalized[:openapi]).to be_kind_of(Hash)
      expect(normalized[:openapi][:servers]).to be_kind_of(Array)
      expect(normalized[:openapi][:servers].first).to eq(config.dig(:openapi, :servers, 0))
      expect(normalized[:openapi][:tags]).to be_kind_of(Hash)
      expect(normalized[:openapi][:security_schemes]).to be_kind_of(Hash)
    end

    context "when 'info' is nil" do
      before do
        config[:info] = nil
      end

      it do
        expect { normalized }.to raise_error(SpecForge::Error::InvalidStructureError) do |e|
          expect(e.message).to include(
            "Expected String, got NilClass for \"title\" in \"info\" in documentation config"
          )

          expect(e.message).to include(
            "Expected String, got NilClass for \"version\" in \"info\" in documentation config"
          )
        end
      end
    end

    context "when 'info' is not a Hash" do
      before do
        config[:info] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected Hash, got Integer for \"info\" in documentation config"
        )
      end
    end

    context "when 'info.title' is nil" do
      before do
        config[:info][:title] = nil
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected String, got NilClass for \"title\" in \"info\" in documentation config"
        )
      end
    end

    context "when 'info.title' is not a String" do
      before do
        config[:info][:title] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected String, got Integer for \"title\" in \"info\" in documentation config"
        )
      end
    end

    context "when 'info.version' is nil" do
      before do
        config[:info][:version] = nil
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected String, got NilClass for \"version\" in \"info\" in documentation config"
        )
      end
    end

    context "when 'info.version' is not a String" do
      before do
        config[:info][:version] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected String, got Integer for \"version\" in \"info\" in documentation config"
        )
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

        expect(normalized[:openapi]).to be_kind_of(Hash)
        expect(normalized[:openapi][:servers]).to be_kind_of(Array)
        expect(normalized[:openapi][:tags]).to be_kind_of(Hash)
        expect(normalized[:openapi][:security_schemes]).to be_kind_of(Hash)
      end
    end
  end
end
