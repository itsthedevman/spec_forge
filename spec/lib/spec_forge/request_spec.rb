# frozen_string_literal: true

RSpec.describe SpecForge::Request do
  let(:url) { "/users" }
  let(:method) {}
  let(:content_type) {}
  let(:query) {}
  let(:body) {}
  let(:options) { {url:, method:, content_type:, query:, body:} }

  subject(:request) { described_class.new(**options) }

  describe "#initialize" do
    it "defaults content_type to application/json" do
      expect(request.content_type).to be_kind_of(MIME::Type)
      expect(request.content_type).to eq("application/json")
    end

    it "defaults http_method to GET" do
      expect(request.http_method).to be_kind_of(SpecForge::HTTPMethod::Get)
    end

    context "when params are provided" do
      let(:query) { {id: Faker::String.random, filter: "faker.string.random"} }

      it "is expected to convert them to Attribute" do
        expect(request.query).to match(
          hash_including(
            id: be_kind_of(SpecForge::Attribute::Literal),
            filter: be_kind_of(SpecForge::Attribute::Faker)
          )
        )
      end
    end

    context "when 'content_type' is not a valid MIME type" do
      let(:content_type) { "in/valid" }

      it { expect { request }.to raise_error(ArgumentError) }
    end

    context "when 'query' is not a Hash" do
      let(:query) { "raw_params=are%20not%20allowed" }

      it do
        expect { request }.to raise_error(
          SpecForge::InvalidTypeError, "Expected Hash, got String for 'query'"
        )
      end
    end

    context "when 'content_type' is json but 'body' is not a Hash" do
      # Default content_type is already json
      let(:body) { "not_a_hash" }

      it do
        expect { request }.to raise_error(
          SpecForge::InvalidTypeError, "Expected Hash, got String for 'body'"
        )
      end
    end

    context "when 'http_method' is mixed case" do
      let(:method) { "DeLeTe" }

      it "works because it is case insensitive" do
        expect(request.http_method).to eq("DELETE")
      end
    end

    describe "Aliases" do
      context "when 'http_method' is given instead of 'method'" do
        let(:method) { "POST" }

        before do
          options[:http_method] = options.delete(:method)
        end

        it "supports the alias" do
          expect(request.http_method).to eq("POST")
        end
      end

      context "when 'params' is given instead of 'query'" do
        let(:query) { {foo: "bar"} }

        before do
          options[:params] = options.delete(:query)
        end

        it "supports the alias" do
          expect(request.query).to eq({foo: "bar"})
        end
      end

      context "when 'path' is given instead of 'url'" do
        let(:url) { "/users/:id/edit" }

        before do
          options[:path] = options.delete(:url)
        end

        it "supports the alias" do
          expect(request.url).to eq("/users/:id/edit")
        end
      end

      context "when 'data' is given instead of 'body'" do
        let(:body) { {foo: "bar"} }

        before do
          options[:data] = options.delete(:body)
        end

        it "supports the alias" do
          expect(request.body).to eq({foo: "bar"})
        end
      end
    end
  end

  describe "#with" do
    subject(:updated_request) { request.with(content_type: "text/plain", method: "POST") }

    it "converts the new attributes correctly" do
      expect(updated_request.content_type).to eq("text/plain")
      expect(updated_request.http_method).to eq("POST")
    end
  end
end
