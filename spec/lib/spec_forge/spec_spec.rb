# frozen_string_literal: true

RSpec.describe SpecForge::Spec do
  let(:name) { Faker::String.random }
  let(:path) { "/users" }
  let(:method) {}
  let(:content_type) {}
  let(:params) {}
  let(:body) {}
  let(:expectations) {}

  subject(:spec) do
    described_class.new(name:, path:, method:, content_type:, params:, body:, expectations:)
  end

  context "when the minimal is given" do
    it "is valid" do
      expect(spec).to be_kind_of(described_class)
    end

    it "defaults content_type to application/json" do
      expect(spec.content_type).to be_kind_of(MIME::Type)
      expect(spec.content_type).to eq("application/json")
    end

    it "defaults http_method to GET" do
      expect(spec.http_method).to be_kind_of(SpecForge::HTTPMethod::Get)
    end
  end

  context "when params are provided" do
    let(:params) { {id: Faker::String.random, filter: "faker.string.random"} }

    it "is expected to convert them to Attribute" do
      expect(spec.params).to match(
        hash_including(
          id: be_kind_of(SpecForge::Attribute::Literal),
          filter: be_kind_of(SpecForge::Attribute::Faker)
        )
      )
    end
  end

  context "when 'content_type' is not a valid MIME type" do
    let(:content_type) { "in/valid" }

    it { expect { spec }.to raise_error(ArgumentError) }
  end

  context "when 'params' is not a Hash" do
    let(:params) { "raw_params=are%20not%20allowed" }

    it { expect { spec }.to raise_error(TypeError, "Expected Hash, got String for 'params'") }
  end

  context "when 'content_type' is json but 'body' is not a Hash" do
    # Default content_type is already json
    let(:body) { "not_a_hash" }

    it { expect { spec }.to raise_error(TypeError, "Expected Hash, got String for 'body'") }
  end
end
