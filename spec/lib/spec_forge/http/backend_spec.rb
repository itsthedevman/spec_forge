# frozen_string_literal: true

RSpec.describe SpecForge::HTTP::Backend do
  context "when the 'url' has placeholders" do
    let(:url) {}
    let(:query) { {} }

    let(:request) do
      SpecForge::HTTP::Request.new(
        **SpecForge::Attribute.from(SpecForge::Normalizer.default_expectation)
      )
    end

    subject(:result) { described_class.new(request).send(:normalize_url, url, query) }

    context "and they are curly style" do
      let(:url) { "/user/{query_1}" }
      let(:query) { {query_1: "hello"} }

      it "is expected to replace the placeholder" do
        expect(result).to eq("/user/hello")
      end
    end

    context "and they are colon style" do
      let(:url) { "/user/:query_1" }
      let(:query) { {query_1: "hello"} }

      it "is expected to replace the placeholder" do
        expect(result).to eq("/user/hello")
      end
    end

    context "and the query attribute isn't defined" do
      let(:url) { "/user/{query_1}" }

      it do
        expect { result }.to raise_error(
          URI::InvalidURIError,
          "#{url.inspect} is not a valid URI. If you're using path parameters (like ':id' or '{id}'), ensure they are defined in the 'query' section."
        )
      end
    end

    context "and the query contains invalid URI content" do
      let(:url) { "/user/:query_1" }
      let(:query) { {query_1: "hello world"} }

      it "is expected to replace the placeholder with URI encoded value" do
        expect(result).to eq("/user/hello%20world")
      end
    end
  end
end
