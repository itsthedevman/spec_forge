# frozen_string_literal: true

RSpec.describe SpecForge::Request do
  let(:path) { "/users" }
  let(:method) {}
  let(:content_type) {}
  let(:params) {}
  let(:body) {}

  subject(:request) do
    described_class.new(path:, method:, content_type:, params:, body:)
  end

  describe "#initialize" do
    it "defaults content_type to application/json" do
      expect(request.content_type).to be_kind_of(MIME::Type)
      expect(request.content_type).to eq("application/json")
    end

    it "defaults http_method to GET" do
      expect(request.http_method).to be_kind_of(SpecForge::HTTPMethod::Get)
    end

    context "when params are provided" do
      let(:params) { {id: Faker::String.random, filter: "faker.string.random"} }

      it "is expected to convert them to Attribute" do
        expect(request.params).to match(
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

    context "when 'params' is not a Hash" do
      let(:params) { "raw_params=are%20not%20allowed" }

      it do
        expect { request }.to raise_error(
          SpecForge::InvalidTypeError, "Expected Hash, got String for 'params'"
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
  end

  describe "#with" do
    subject(:updated_request) { request.with(content_type: "text/plain", method: "POST") }

    it "converts the new attributes correctly" do
      expect(updated_request.content_type).to eq("text/plain")
      expect(updated_request.http_method).to eq("POST")
    end
  end
end
