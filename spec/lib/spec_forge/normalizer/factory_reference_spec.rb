# frozen_string_literal: true

# This is more for organizational purposes
RSpec.describe SpecForge::Normalizer do
  describe ".normalize_factory_reference!" do
    let(:factory) do
      {
        build_strategy: "create",
        attributes: {
          name: "faker.name.name"
        },
        size: 1
      }
    end

    subject(:normalized) { described_class.normalize_factory_reference!(factory) }

    it "is expected to normalize normally" do
      expect(normalized[:build_strategy]).to eq("create")
      expect(normalized[:attributes]).to match(name: "faker.name.name")
    end

    context "when 'build_strategy' is nil" do
      before { factory[:build_strategy] = nil }

      it "is expected to default to 'create'" do
        expect(normalized[:build_strategy]).to eq("create")
      end
    end

    context "when 'attributes' is nil" do
      before { factory[:attributes] = nil }

      it "is expected to default to an empty hash" do
        expect(normalized[:attributes]).to eq({})
      end
    end

    context "when 'size' is nil" do
      before { factory[:size] = nil }

      it "is expected to default to 0" do
        expect(normalized[:size]).to eq(0)
      end
    end

    context "when aliases are used" do
      before do
        factory[:build_strategy] = "build"
        factory[:strategy] = factory.delete(:build_strategy)
        factory[:count] = factory.delete(:size)
      end

      it "is expected to accept the aliases" do
        expect(normalized[:build_strategy]).to eq(factory[:strategy])
        expect(normalized[:size]).to eq(factory[:count])
      end
    end

    include_examples(
      "normalizer_raises_invalid_structure",
      {
        context: "when 'build_strategy' is not a String",
        before: -> { factory[:build_strategy] = 1 },
        error: "Expected String, got Integer for \"build_strategy\" (aliases \"strategy\") in factory reference"
      },
      {
        context: "when 'attributes' is not a Hash",
        before: -> { factory[:attributes] = 1 },
        error: "Expected Hash, got Integer for \"attributes\" in factory reference"
      },
      {
        context: "when 'size' is not an Integer",
        before: -> { factory[:size] = 1.0 },
        error: "Expected Integer, got Float for \"size\" (aliases \"count\") in factory reference"
      }
    )
  end
end
