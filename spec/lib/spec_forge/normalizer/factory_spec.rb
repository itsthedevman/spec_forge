# frozen_string_literal: true

# This is more for organizational purposes
RSpec.describe SpecForge::Normalizer do
  describe ".normalize_factory!" do
    let(:factory) do
      {
        model_class: "User",
        variables: {
          var_1: "faker.number.positive",
          var_2: "Variable 2"
        },
        attributes: {
          id: "variables.var_1",
          name: "faker.name.name"
        }
      }
    end

    subject(:normalized) { described_class.normalize_factory!(factory) }

    it "is expected to normalize fully" do
      expect(normalized[:model_class]).to eq("User")
      expect(normalized[:variables]).to match(
        var_1: "faker.number.positive",
        var_2: "Variable 2"
      )

      expect(normalized[:attributes]).to match(
        id: "variables.var_1",
        name: "faker.name.name"
      )
    end

    context "when aliases are used" do
      before do
        factory[:class] = factory.delete(:model_class)
      end

      it "is expected to normalize" do
        expect(normalized[:model_class]).to eq(factory[:class])
      end
    end

    context "when 'model_class' is nil" do
      before { factory[:model_class] = nil }

      it "is expected to default to an empty string" do
        expect(normalized[:model_class]).to eq("")
      end
    end

    context "when 'variables' is nil" do
      before { factory[:variables] = nil }

      it "is expected to default to an empty hash" do
        expect(normalized[:variables]).to eq({})
      end
    end

    context "when 'attributes' is nil" do
      before { factory[:attributes] = nil }

      it "is expected to default to an empty hash" do
        expect(normalized[:attributes]).to eq({})
      end
    end

    include_examples(
      "normalizer_raises_invalid_structure",
      {
        context: "when 'model_class' is not a String",
        before: -> { factory[:model_class] = 1 },
        error: "Expected String, got Integer for \"model_class\" (aliases \"class\") in factory"
      },
      {
        context: "when 'variables' is not a Hash",
        before: -> { factory[:variables] = 1 },
        error: "Expected Hash or String, got Integer for \"variables\" in factory"
      },
      {
        context: "when 'attributes' is not a Hash",
        before: -> { factory[:attributes] = 1 },
        error: "Expected Hash, got Integer for \"attributes\" in factory"
      }
    )
  end
end
