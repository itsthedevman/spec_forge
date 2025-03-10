# frozen_string_literal: true

RSpec.describe SpecForge::Normalizer do
  describe "#normalize_to_structure" do
    let(:input) {}

    let(:structure) do
      {
        nested: {
          type: Hash,
          structure: {
            key_1: {type: String},
            key_2: {
              type: Hash,
              structure: {
                key_3: {type: String}
              }
            }
          }
        }
      }
    end

    subject(:normalized) do
      described_class.new("normalizer", input, structure:).normalize
    end

    context "when a structure has a valid sub_structure" do
      let(:input) do
        {
          nested: {
            key_1: Faker::String.random,
            key_2: {
              key_3: Faker::String.random
            }
          }
        }
      end

      it "is expected to resolve correctly" do
        output, errors = normalized
        expect(errors).to be_empty
        expect(output[:nested][:key_2][:key_3]).to eq(input[:nested][:key_2][:key_3])
      end
    end

    context "when a structure does not have a valid sub structure" do
      let(:input) do
        {
          nested: {
            key_1: "",
            key_2: {
              key_3: 1
            }
          }
        }
      end

      it do
        _, errors = normalized

        expect(errors).not_to be_empty

        error = errors.first

        expect(error).to be_kind_of(SpecForge::Error::InvalidTypeError)
        expect(error.message).to eq(
          "Expected String, got Integer for \"key_3\" in normalizer"
        )
      end
    end

    context "when a structure is not the same type as the value" do
      let(:input) { {mixed_type: "string_or_hash"} }

      let(:structure) do
        {
          mixed_type: {
            type: [String, Hash],
            structure: {
              var_1: {type: String}
            }
          }
        }
      end

      it "skips over structure validation" do
        output, errors = normalized
        expect(errors).to be_empty

        expect(output[:mixed_type]).to eq("string_or_hash")
      end
    end
  end
end
