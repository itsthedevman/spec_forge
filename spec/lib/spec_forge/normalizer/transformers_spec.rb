# frozen_string_literal: true

RSpec.describe SpecForge::Normalizer::Transformers do
  describe "#normalize_shape" do
    let(:shape) {}

    subject(:normalized_shape) { described_class.call(:normalize_shape, shape) }

    context "when it is a flat hash" do
      let(:shape) do
        {id: "integer", email: "string", active: "boolean"}
      end

      it "is expected to transform into a shape" do
        is_expected.to eq(
          type: [Hash],
          structure: {
            id: {type: [Integer]},
            email: {type: [String]},
            active: {type: [TrueClass, FalseClass]}
          }
        )
      end
    end

    context "when it has a nested hash" do
      let(:shape) do
        {id: "integer", user: {name: "string", role: "?string"}}
      end

      it "is expected to transform into a shape" do
        is_expected.to eq(
          type: [Hash],
          structure: {
            id: {type: [Integer]},
            user: {
              type: [Hash],
              structure: {
                name: {type: [String]},
                role: {type: [String, NilClass]}
              }
            }
          }
        )
      end
    end

    context "when it is an array of objects" do
      let(:shape) do
        [{id: "integer", name: "string"}]
      end

      it "is expected to transform into a pattern shape" do
        is_expected.to eq(
          type: [Array],
          pattern: {
            type: [Hash],
            structure: {
              id: {type: [Integer]},
              name: {type: [String]}
            }
          }
        )
      end
    end

    context "when it is an array of primitives" do
      let(:shape) do
        {tags: ["string"]}
      end

      it "is expected to transform into a pattern shape" do
        is_expected.to eq(
          type: [Hash],
          structure: {
            tags: {
              type: [Array],
              pattern: {type: [String]}
            }
          }
        )
      end
    end

    context "when it is nested array" do
      let(:shape) do
        [
          {
            id: "integer",
            title: "string",
            user: {login: "string"},
            labels: [
              {name: "string", color: "string"}
            ]
          }
        ]
      end

      it "is expected to transform into a pattern shape" do
        is_expected.to eq(
          type: [Array],
          pattern: {
            type: [Hash],
            structure: {
              id: {type: [Integer]},
              title: {type: [String]},
              user: {
                type: [Hash],
                structure: {
                  login: {type: [String]}
                }
              },
              labels: {
                type: [Array],
                pattern: {
                  type: [Hash],
                  structure: {
                    name: {type: [String]},
                    color: {type: [String]}
                  }
                }
              }
            }
          }
        )
      end
    end

    context "when it is a top-level primitive" do
      let(:shape) { "string" }

      it "is expected to transform into a type" do
        is_expected.to eq(type: [String])
      end
    end

    context "when it is an empty hash" do
      let(:shape) { {} }

      it "is expected to transform into an empty structure" do
        is_expected.to eq(type: [Hash], structure: {})
      end
    end

    context "when it is an empty array" do
      let(:shape) { [] }

      it "is expected to transform into an array with no pattern" do
        is_expected.to eq(type: [Array])
      end
    end

    context "when it is nil" do
      let(:shape) { nil }

      it "is expected to raise an ArgumentError" do
        expect { normalized_shape }.to raise_error(ArgumentError, /Shape cannot be nil/)
      end
    end

    context "when it is a multi-element array (tuple)" do
      let(:shape) do
        [{id: "integer"}, {name: "string"}]
      end

      it "is expected to transform into a structure with indexed elements" do
        is_expected.to eq(
          type: [Array],
          structure: [
            {type: [Hash], structure: {id: {type: [Integer]}}},
            {type: [Hash], structure: {name: {type: [String]}}}
          ]
        )
      end
    end

    context "when it has nested arrays of primitives" do
      let(:shape) do
        {matrix: [["integer"]]}
      end

      it "is expected to transform into nested array patterns" do
        is_expected.to eq(
          type: [Hash],
          structure: {
            matrix: {
              type: [Array],
              pattern: {
                type: [Array],
                pattern: {type: [Integer]}
              }
            }
          }
        )
      end
    end
  end

  describe "#normalize_schema" do
    let(:schema) {}

    subject(:normalized_schema) { described_class.call(:normalize_schema, schema) }

    context "when it is nil" do
      let(:schema) { nil }

      it "is expected to raise an ArgumentError" do
        expect { normalized_schema }.to raise_error(ArgumentError, /Schema cannot be nil/)
      end
    end

    context "when it is a string" do
      let(:schema) { "integer" }

      it "is expected to wrap in a type hash" do
        is_expected.to eq(type: [Integer])
      end
    end

    context "when it is a hash with a string type" do
      let(:schema) do
        {type: "string"}
      end

      it "is expected to convert the type to an array of classes" do
        is_expected.to eq(type: [String])
      end
    end

    context "when it is a hash with a nested structure (Hash) with string values" do
      let(:schema) do
        {type: "hash", structure: {id: "integer", email: "string"}}
      end

      it "is expected to recursively normalize structure values" do
        is_expected.to eq(
          type: [Hash],
          structure: {
            id: {type: [Integer]},
            email: {type: [String]}
          }
        )
      end
    end

    context "when it is a hash with a nested structure (Hash) with hash values" do
      let(:schema) do
        {type: "hash", structure: {id: {type: "integer"}, name: {type: "string"}}}
      end

      it "is expected to recursively normalize structure values" do
        is_expected.to eq(
          type: [Hash],
          structure: {
            id: {type: [Integer]},
            name: {type: [String]}
          }
        )
      end
    end

    context "when it is a hash with a nested structure (Array)" do
      let(:schema) do
        {type: "array", structure: [{type: "string"}, {type: "integer"}]}
      end

      it "is expected to recursively normalize array elements" do
        is_expected.to eq(
          type: [Array],
          structure: [{type: [String]}, {type: [Integer]}]
        )
      end
    end

    context "when it is a hash with a pattern" do
      let(:schema) do
        {type: "array", pattern: {type: "string"}}
      end

      it "is expected to recursively normalize the pattern" do
        is_expected.to eq(
          type: [Array],
          pattern: {type: [String]}
        )
      end
    end

    context "when it is an array" do
      let(:schema) do
        [{type: "string"}, {type: "integer"}]
      end

      it "is expected to recursively normalize each element in-place" do
        is_expected.to eq([{type: [String]}, {type: [Integer]}])
      end
    end

    context "when it has deep nesting with structure and pattern" do
      let(:schema) do
        {
          type: "hash",
          structure: {
            items: {
              type: "array",
              pattern: {type: "string"}
            }
          }
        }
      end

      it "is expected to recursively normalize all levels" do
        is_expected.to eq(
          type: [Hash],
          structure: {
            items: {
              type: [Array],
              pattern: {type: [String]}
            }
          }
        )
      end
    end

    context "when the hash has no type key" do
      let(:schema) do
        {structure: {id: {type: "integer"}}}
      end

      it "is expected to pass through and only normalize nested types" do
        is_expected.to eq(structure: {id: {type: [Integer]}})
      end
    end

    context "when the hash has an already-converted type" do
      let(:schema) do
        {type: [String], structure: {id: {type: "integer"}}}
      end

      it "is expected to leave the type unchanged and normalize nested types" do
        is_expected.to eq(
          type: [String],
          structure: {id: {type: [Integer]}}
        )
      end
    end
  end

  describe "#normalize_callback" do
    subject(:callback) { described_class.call(:normalize_callback, value) }

    context "when the value is a string" do
      let(:value) { "my_method" }

      it "is expected to return an array with a hash containing the name" do
        is_expected.to eq([{name: "my_method"}])
      end
    end

    context "when the value is a symbol" do
      let(:value) { :my_method }

      it "is expected to return an array with a hash containing the symbol as the name" do
        is_expected.to eq([{name: :my_method}])
      end
    end

    context "when the value is a hash" do
      let(:value) { {name: "my_method", arguments: {}} }

      it "is expected to return an array containing the hash" do
        is_expected.to eq([value])
      end
    end

    context "when the value is a hash with only a name" do
      let(:value) { {name: "my_method"} }

      it "is expected to return an array containing the hash" do
        is_expected.to eq([value])
      end
    end

    context "when the value is an array" do
      let(:value) do
        [
          {name: "my_method"},
          "my_other_method"
        ]
      end

      it "is expected to return an array with each element normalized" do
        is_expected.to eq([
          {name: "my_method"},
          {name: "my_other_method"}
        ])
      end
    end

    context "when the value is an array of only strings" do
      let(:value) { ["first_callback", "second_callback"] }

      it "is expected to normalize each string to a hash" do
        is_expected.to eq([
          {name: "first_callback"},
          {name: "second_callback"}
        ])
      end
    end

    context "when the value is an array of only hashes" do
      let(:value) do
        [
          {name: "first", arguments: {id: 1}},
          {name: "second", arguments: {id: 2}}
        ]
      end

      it "is expected to return the array unchanged" do
        is_expected.to eq(value)
      end
    end

    context "when the value is an empty array" do
      let(:value) { [] }

      it "is expected to return nil" do
        is_expected.to be_nil
      end
    end
  end

  describe "#abs" do
    subject(:result) { described_class.call(:abs, value) }

    context "when the value is a positive integer" do
      let(:value) { 42 }

      it "is expected to return the same value" do
        is_expected.to eq(42)
      end
    end

    context "when the value is a negative integer" do
      let(:value) { -42 }

      it "is expected to return the absolute value" do
        is_expected.to eq(42)
      end
    end

    context "when the value is zero" do
      let(:value) { 0 }

      it "is expected to return zero" do
        is_expected.to eq(0)
      end
    end

    context "when the value is a positive float" do
      let(:value) { 3.14 }

      it "is expected to return the same value" do
        is_expected.to eq(3.14)
      end
    end

    context "when the value is a negative float" do
      let(:value) { -3.14 }

      it "is expected to return the absolute value" do
        is_expected.to eq(3.14)
      end
    end

    context "when the value is nil" do
      let(:value) { nil }

      it "is expected to return nil" do
        is_expected.to be_nil
      end
    end
  end
end
