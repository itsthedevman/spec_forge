# frozen_string_literal: true

RSpec.describe SpecForge::Normalizer do
  describe "#normalize" do
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
          "Expected String, got Integer for \"key_3\" in \"key_2\" in \"nested\" in normalizer"
        )
      end
    end

    context "when the types do not support structure checking" do
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

    context "when the value is Array and the structure is Hash" do
      let(:input) do
        {
          array_of_strings: ["hello", "world", "!"],
          array_of_bools: [true, false, true, false],
          array_of_objects: [{var: 1}, {var: 1}, {var: 1}]
        }
      end

      let(:structure) do
        {
          array_of_strings: {
            type: Array,
            structure: {type: String}
          },
          array_of_bools: {
            type: Array,
            structure: {type: [TrueClass, FalseClass]}
          },
          array_of_objects: {
            type: Array,
            structure: {
              type: Hash,
              structure: {
                var: {type: Integer}
              }
            }
          }
        }
      end

      it "is expected to validate each element of the array against the structure" do
        output, errors = normalized
        expect(errors).to be_empty

        expect(output[:array_of_strings]).to contain_exactly("hello", "world", "!")
        expect(output[:array_of_bools]).to contain_exactly(true, false, true, false)
        expect(output[:array_of_objects]).to contain_exactly({var: 1}, {var: 1}, {var: 1})
      end
    end

    context "when an attribute is not required" do
      let(:input) do
        {callbacks: [{before: ""}]}
      end

      let(:structure) do
        {
          callbacks: {
            type: Array,
            default: [],
            structure: {
              type: Hash,
              default: {},
              structure: {
                before: {
                  type: String
                },
                after: {
                  type: String,
                  required: false
                },
                and_everything_in_between: {
                  type: String,
                  default: nil
                }
              }
            }
          }
        }
      end

      it "is expected to not include the default empty structure" do
        output, errors = normalized
        expect(errors).to be_empty

        expect(output).to eq(callbacks: [{before: "", and_everything_in_between: nil}])
      end
    end

    context "when the input contains extra keys not defined in the structure" do
      context "and it is at the root level" do
        let(:input) do
          {
            foo: "hello",
            bar: "world",
            baz: "extra"
          }
        end

        let(:structure) do
          {
            foo: {type: String},
            bar: {type: String}
          }
        end

        it "ignores extra keys and does not include them in the output" do
          output, errors = normalized
          expect(errors).to be_empty

          expect(output).to eq(foo: "hello", bar: "world")
          expect(output).not_to have_key(:baz)
        end
      end

      context "and it is in a nested structure" do
        let(:input) do
          {
            nested: {
              key_1: "value",
              key_2: {
                key_3: "nested_value",
                extra_nested: "should be ignored"
              },
              extra_key: "should also be ignored"
            }
          }
        end

        it "ignores extra keys at all nesting levels" do
          output, errors = normalized
          expect(errors).to be_empty

          expect(output[:nested]).to eq(key_1: "value", key_2: {key_3: "nested_value"})
          expect(output[:nested]).not_to have_key(:extra_key)
          expect(output[:nested][:key_2]).not_to have_key(:extra_nested)
        end
      end

      context "and some extra keys have invalid types" do
        let(:input) do
          {
            foo: "valid",
            bar: "also valid",
            extra_with_bad_type: 12345
          }
        end

        let(:structure) do
          {
            foo: {type: String},
            bar: {type: String}
          }
        end

        it "does not validate or error on the extra keys" do
          output, errors = normalized
          expect(errors).to be_empty

          expect(output).to eq(foo: "valid", bar: "also valid")
        end
      end
    end

    context "when the structure uses '*'" do
      context "and it is used as a root key" do
        let(:input) do
          {
            specific: "",
            all: 1,
            other: 2,
            keys: 3
          }
        end

        let(:structure) do
          {
            :specific => {type: String},
            :* => {type: Integer}
          }
        end

        it "is expected to normalize any extra keys" do
          output, errors = normalized
          expect(errors).to be_empty

          expect(output).to eq(input)
        end
      end

      context "and it is used in a nested structure" do
        let(:input) do
          {
            specific: {
              any: "",
              key: nil,
              works: ""
            }
          }
        end

        let(:structure) do
          {
            specific: {
              type: Hash,
              structure: {
                "*" => {type: String, default: ""}
              }
            }
          }
        end

        it "is expected to normalize any extra keys" do
          output, errors = normalized
          expect(errors).to be_empty

          expect(output).to eq(specific: {
            any: "", key: "", works: ""
          })
        end
      end
    end
  end
end
