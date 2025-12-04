# frozen_string_literal: true

RSpec.describe SpecForge::HTTP::Request do
  let(:base_url) { "http://localhost:3000" }
  let(:url) { "/users" }
  let(:http_verb) { "GET" }
  let(:headers) { {} }
  let(:query) { {} }
  let(:raw) { "" }
  let(:json) { {} }

  let(:options) do
    {base_url:, url:, http_verb:, headers:, query:, raw:, json:}
  end

  subject(:request) { described_class.new(**options) }

  describe "#initialize" do
    it "defaults http_verb to GET" do
      expect(request.http_verb).to be_kind_of(SpecForge::HTTP::Verb::Get)
    end

    context "when 'headers' are provided" do
      let(:headers) { {:content_type => "custom/type", "Custom-Header-2" => "value"} }

      it "normalizes header keys to HTTP-Case" do
        expect(request.headers.resolved).to include(
          "Content-Type" => "custom/type",
          "Custom-Header-2" => "value"
        )
      end
    end

    context "when 'base_url' is provided" do
      it "uses the provided base_url" do
        expect(request.base_url).to eq(base_url)
      end
    end

    context "when 'query' is provided" do
      let(:query) { {filter: "faker.string.random"} }

      it "converts values to Attributes" do
        expect(request.query[:filter]).to be_kind_of(SpecForge::Attribute::Faker)
        expect(request.query[:filter].value).to be_kind_of(String)
      end
    end

    context "when 'http_verb' is mixed case" do
      let(:http_verb) { "DeLeTe" }

      it "works because it is case insensitive" do
        expect(request.http_verb).to eq("DELETE")
      end
    end

    describe "content handling" do
      context "when 'json' is provided" do
        let(:json) { {name: "Test User", age: 25} }

        it "converts json to ResolvableHash" do
          expect(request.body).to be_kind_of(SpecForge::Attribute::ResolvableHash)
        end

        it "preserves the structure for later resolution" do
          expect(request.body.resolved).to eq(name: "Test User", age: 25)
        end

        it "sets Content-Type to application/json" do
          expect(request.content_type.resolved).to eq("application/json")
        end

        context "with Faker attributes" do
          let(:json) { {name: "faker.name.name", email: "faker.internet.email"} }

          it "converts nested values to Attributes" do
            expect(request.body[:name]).to be_kind_of(SpecForge::Attribute::Faker)
            expect(request.body[:email]).to be_kind_of(SpecForge::Attribute::Faker)
          end

          it "resolves Faker values when accessed" do
            expect(request.body[:name].resolved).to be_kind_of(String)
            expect(request.body[:email].resolved).to be_kind_of(String)
          end
        end
      end

      context "when 'raw' is provided" do
        let(:raw) { "username=test&password=123" }

        it "uses the raw string as body" do
          expect(request.body.resolved).to eq(raw)
        end

        it "sets Content-Type to text/plain by default" do
          expect(request.content_type.resolved).to eq("text/plain")
        end

        context "with custom Content-Type header" do
          let(:headers) { {"Content-Type" => "application/x-www-form-urlencoded"} }

          it "respects the provided Content-Type" do
            expect(request.content_type.resolved).to eq("application/x-www-form-urlencoded")
          end
        end
      end

      context "when both 'json' and 'raw' are blank" do
        it "defaults to empty raw body" do
          expect(request.body.resolved).to eq("")
        end

        it "sets Content-Type to text/plain" do
          expect(request.content_type.resolved).to eq("text/plain")
        end
      end

      context "when both 'json' and 'raw' are provided" do
        let(:json) { {data: "json"} }
        let(:raw) { "raw data" }

        it "json takes precedence" do
          expect(request.body.resolved).to eq(data: "json")
        end

        it "sets Content-Type to application/json" do
          expect(request.content_type.resolved).to eq("application/json")
        end
      end
    end
  end
end
