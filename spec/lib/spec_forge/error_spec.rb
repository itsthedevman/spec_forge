# frozen_string_literal: true

RSpec.describe SpecForge::Error do
  describe SpecForge::InvalidFakerClassError do
    let(:input) { "faker.nuumbre" }

    subject(:error) { described_class.new(input) }

    it "will provide them in the error" do
      expect(error.message).to match("Did you mean?")
    end
  end

  describe SpecForge::InvalidFakerMethodError do
    let(:input) { "psoitive" }

    subject(:error) { described_class.new(input, Faker::Number) }

    it "will provide them in the error" do
      expect(error.message).to match("Did you mean?")
    end
  end

  describe SpecForge::InvalidTypeError do
    let(:input) { nil }
    let(:expected_type) {}
    let(:for_thing) {}

    subject(:error) { described_class.new(input, expected_type, for: for_thing) }

    context "when the expected_type is a class" do
      let(:expected_type) { Hash }

      it do
        expect(error.message).to eq("Expected Hash, got NilClass")
      end
    end

    context "when the expected_type is an Array of classes" do
      let(:expected_type) { [String, Integer] }

      it do
        expect(error.message).to eq("Expected String or Integer, got NilClass")
      end

      context "and there are more than two classes" do
        let(:expected_type) { [String, Integer, Array] }

        it do
          expect(error.message).to eq("Expected String, Integer, or Array, got NilClass")
        end
      end
    end

    context "when 'for' is provided" do
      let(:expected_type) { String }
      let(:for_thing) { "'attribute'" }

      it do
        expect(error.message).to eq("Expected String, got NilClass for 'attribute'")
      end
    end
  end
end
