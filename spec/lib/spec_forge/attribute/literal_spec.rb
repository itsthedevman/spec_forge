# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Literal do
  let(:input) {}

  subject(:attribute) { described_class.new(input) }

  include_examples "from_input_to_attribute" do
    let(:input) { 1 }
  end

  describe "#value" do
    subject(:value) { attribute.value }

    context "when input is a string" do
      let(:input) { Faker::String.random }

      it "is expected to return the exact value" do
        expect(value).to eq(input)
      end
    end

    context "when input is a integer" do
      let(:input) { Faker::Number.positive.to_i }

      it "is expected to return the exact value" do
        expect(value).to eq(input)
      end
    end

    context "when input is a float" do
      let(:input) { Faker::Number.positive.to_f }

      it "is expected to return the exact value" do
        expect(value).to eq(input)
      end
    end

    context "when input is a boolean" do
      let(:input) { Faker::Boolean.boolean }

      it "is expected to return the exact value" do
        expect(value).to eq(input)
      end
    end

    context "when input is an array" do
      let(:input) { [1] }

      it "is expected to return the exact value" do
        expect(value).to eq([described_class.new(1)])
      end
    end

    context "when input is a hash" do
      let(:input) { {foo: "bar"} }

      it "is expected to return the exact value" do
        expect(value).to eq(input)
      end
    end
  end
end
