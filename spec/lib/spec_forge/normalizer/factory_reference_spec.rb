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

      it do
        expect(normalized[:build_strategy]).to eq("create")
      end
    end

    context "when 'build_strategy' is not a String" do
      before { factory[:build_strategy] = 1 }

      include_examples "raises_invalid_structure_error" do
        let(:error_message) do
          "Expected String, got Integer for \"build_strategy\" (aliases \"strategy\") in factory reference"
        end
      end
    end

    context "when 'attributes' is nil" do
      before { factory[:attributes] = nil }

      it do
        expect(normalized[:attributes]).to eq({})
      end
    end

    context "when 'attributes' is not a Hash" do
      before { factory[:attributes] = 1 }

      include_examples "raises_invalid_structure_error" do
        let(:error_message) do
          "Expected Hash, got Integer for \"attributes\" in factory reference"
        end
      end
    end

    context "when 'size' is nil" do
      before { factory[:size] = nil }

      it do
        expect(normalized[:size]).to eq(0)
      end
    end

    context "when 'size' is not an Integer" do
      before { factory[:size] = 1.0 }

      include_examples "raises_invalid_structure_error" do
        let(:error_message) do
          "Expected Integer, got Float for \"size\" (aliases \"count\") in factory reference"
        end
      end
    end

    context "when aliases are used" do
      before do
        factory[:build_strategy] = "build"
        factory[:strategy] = factory.delete(:build_strategy)
        factory[:count] = factory.delete(:size)
      end

      it do
        expect(normalized[:build_strategy]).to eq(factory[:strategy])
        expect(normalized[:size]).to eq(factory[:count])
      end
    end
  end
end
