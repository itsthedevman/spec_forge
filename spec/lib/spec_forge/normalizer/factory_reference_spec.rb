# frozen_string_literal: true

# This is more for organizational purposes
RSpec.describe SpecForge::Normalizer do
  describe ".normalize_factory_reference!" do
    let(:factory) do
      {
        build_strategy: "create",
        attributes: {
          name: "faker.name.name"
        }
      }
    end

    subject(:normalized) { described_class.normalize_factory_reference!(factory) }

    it "is expected to normalize normally" do
      expect(normalized[:build_strategy]).to eq("create")
      expect(normalized[:attributes]).to match(name: "faker.name.name")
    end

    context "when 'build_strategy' is nil" do
      before do
        factory[:build_strategy] = nil
      end

      it do
        expect(normalized[:build_strategy]).to eq("create")
      end
    end

    context "when 'build_strategy' is not a String" do
      before do
        factory[:build_strategy] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected String, got Integer for \"build_strategy\" on factory reference"
        )
      end
    end

    context "when 'attributes' is nil" do
      before do
        factory[:attributes] = nil
      end

      it do
        expect(normalized[:attributes]).to eq({})
      end
    end

    context "when 'attributes' is not a Hash" do
      before do
        factory[:attributes] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected Hash, got Integer for \"attributes\" on factory reference"
        )
      end
    end

    context "when aliases are used" do
      before do
        factory[:build_strategy] = "build"
        factory[:strategy] = factory.delete(:build_strategy)
      end

      it do
        expect(normalized[:build_strategy]).to eq(factory[:strategy])
      end
    end
  end
end
