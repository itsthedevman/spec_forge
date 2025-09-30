# frozen_string_literal: true

RSpec.describe SpecForge::HTTP::Backend do
  describe "#normalize_url" do
    let(:request) do
      SpecForge::HTTP::Request.new(**Generator.empty_request_hash)
    end

    let(:backend) { described_class.new(request) }
    let(:query) { {} }

    subject(:result) { backend.send(:normalize_url, url, query) }

    context "when the url has a leading slash" do
      let(:url) { "/users" }

      it "strips the leading slash" do
        expect(result).to eq("users")
      end

      context "with nested paths" do
        let(:url) { "/api/v1/users" }

        it "only strips the first slash" do
          expect(result).to eq("api/v1/users")
        end
      end

      context "with placeholders" do
        let(:url) { "/users/{id}" }
        let(:query) { {id: 123} }

        it "strips the slash and replaces placeholders" do
          expect(result).to eq("users/123")
        end
      end
    end

    context "when the url doesn't have a leading slash" do
      let(:url) { "users" }

      it "leaves the url unchanged" do
        expect(result).to eq("users")
      end

      context "with placeholders" do
        let(:url) { "users/{id}/posts" }
        let(:query) { {id: 456} }

        it "replaces placeholders without adding slashes" do
          expect(result).to eq("users/456/posts")
        end
      end
    end

    context "when the url is an absolute URL" do
      let(:url) { "https://api.example.com/users" }

      it "leaves the absolute URL unchanged" do
        expect(result).to eq("https://api.example.com/users")
      end

      context "with placeholders" do
        let(:url) { "https://api.example.com/users/{id}" }
        let(:query) { {id: 789} }

        it "replaces placeholders in the absolute URL" do
          expect(result).to eq("https://api.example.com/users/789")
        end
      end
    end

    context "when the url is just a slash" do
      let(:url) { "/" }

      it "returns an empty string" do
        expect(result).to eq("")
      end
    end

    context "when the 'url' has placeholders" do
      context "and they are curly style" do
        let(:url) { "/user/{query_1}" }
        let(:query) { {query_1: "hello"} }

        it "is expected to replace the placeholder" do
          expect(result).to eq("user/hello")
        end
      end

      context "and they are colon style" do
        let(:url) { "/user/:query_1" }
        let(:query) { {query_1: "hello"} }

        it "is expected to replace the placeholder" do
          expect(result).to eq("user/hello")
        end
      end

      context "and the query attribute isn't defined" do
        let(:url) { "/user/{query_1}" }

        it do
          expect { result }.to raise_error(
            URI::InvalidURIError,
            "\"user/{query_1}\" is not a valid URI. If you're using path parameters (like ':id' or '{id}'), ensure they are defined in the 'query' section."
          )
        end
      end

      context "and the query contains invalid URI content" do
        let(:url) { "/user/:query_1" }
        let(:query) { {query_1: "hello world"} }

        it "is expected to replace the placeholder with URI encoded value" do
          expect(result).to eq("user/hello%20world")
        end
      end
    end
  end
end
