# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Transform do
  let(:input) { "" }
  let(:positional) { [] }
  let(:keyword) { {} }

  subject(:attribute) { described_class.new(input, positional, keyword) }

  include_examples "from_input_to_attribute" do
    # Transforms are only detected when defined as a hash
    let(:input) { {"transform.join": []} }
  end

  context "when the input is not defined" do
    let(:input) { "" }

    it "is expected to raise" do
      expect { attribute }.to raise_error(SpecForge::Error::InvalidTransformFunctionError)
    end
  end

  describe "transform.join" do
    let(:input) { "transform.join" }

    context "when the joining items are literals" do
      let(:positional) { ["foo", " ", "bar"] }

      it "joins them into one string" do
        expect(attribute.value).to eq("foo bar")
      end
    end

    context "when there are macros" do
      let(:positional) { ["faker.number.positive", " ", "bar"] }

      it "replaces the macro and joins them into one string" do
        expect(attribute.value).to match(/\d+ bar/i)
      end
    end

    # It made me so happy when I realized this would work :D
    context "when there are expanded macros" do
      let(:positional) { [{"faker.number.between": {from: 1, to: 10}}, " ", "bar"] }

      it "replaces the macro and joins them into one string" do
        expect(attribute.value).to match(/\d+ bar/i)
      end
    end
  end
end
