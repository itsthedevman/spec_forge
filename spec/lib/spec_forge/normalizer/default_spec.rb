# frozen_string_literal: true

RSpec.describe SpecForge::Normalizer::Default do
  describe ".default" do
    context "with a predefined structure name" do
      it "returns defaults for the step structure" do
        result = SpecForge::Normalizer.default(:step)
        expect(result).to be_a(Hash)
        expect(result).to have_key(:debug)
      end

      it "raises ArgumentError for unknown structure names" do
        expect {
          SpecForge::Normalizer.default(:nonexistent_structure)
        }.to raise_error(ArgumentError, /No normalizer structure exists/)
      end
    end

    context "with a custom structure" do
      let(:structure) do
        {
          name: {type: String, required: true, default: "default_name"},
          count: {type: Integer, required: true},
          optional_field: {type: String}
        }
      end

      it "returns defaults for required fields" do
        result = SpecForge::Normalizer.default(structure:)
        expect(result[:name]).to eq("default_name")
        expect(result[:count]).to eq(0)
      end

      it "excludes optional fields without defaults by default" do
        result = SpecForge::Normalizer.default(structure:)
        expect(result).not_to have_key(:optional_field)
      end

      it "includes optional fields when include_optional is true" do
        result = SpecForge::Normalizer.default(structure:, include_optional: true)
        expect(result).to have_key(:optional_field)
      end

      it "raises ArgumentError when structure is not a Hash" do
        expect {
          SpecForge::Normalizer.default(structure: "not a hash")
        }.to raise_error(ArgumentError, /must be a Hash/)
      end
    end

    context "with different type defaults" do
      it "returns 0 for Integer type" do
        structure = {value: {type: Integer, required: true}}
        result = SpecForge::Normalizer.default(structure:)
        expect(result[:value]).to eq(0)
      end

      it "returns empty string for String type" do
        structure = {value: {type: String, required: true}}
        result = SpecForge::Normalizer.default(structure:)
        expect(result[:value]).to eq("")
      end

      it "returns empty hash for Hash type" do
        structure = {value: {type: Hash, required: true}}
        result = SpecForge::Normalizer.default(structure:)
        expect(result[:value]).to eq({})
      end

      it "returns empty array for Array type" do
        structure = {value: {type: Array, required: true}}
        result = SpecForge::Normalizer.default(structure:)
        expect(result[:value]).to eq([])
      end

      it "returns true for TrueClass type" do
        structure = {value: {type: TrueClass, required: true}}
        result = SpecForge::Normalizer.default(structure:)
        expect(result[:value]).to eq(true)
      end

      it "returns false for FalseClass type" do
        structure = {value: {type: FalseClass, required: true}}
        result = SpecForge::Normalizer.default(structure:)
        expect(result[:value]).to eq(false)
      end

      it "returns a proc for Proc type" do
        structure = {value: {type: Proc, required: true}}
        result = SpecForge::Normalizer.default(structure:)
        expect(result[:value]).to be_a(Proc)
      end
    end

    context "with array type definitions" do
      it "uses the first type in the array for defaults" do
        structure = {value: {type: [String, Integer], required: true}}
        result = SpecForge::Normalizer.default(structure:)
        expect(result[:value]).to eq("")
      end
    end

    context "with nil defaults" do
      it "skips fields with nil as default value" do
        structure = {value: {type: String, default: nil}}
        result = SpecForge::Normalizer.default(structure:)
        expect(result).not_to have_key(:value)
      end
    end
  end
end
