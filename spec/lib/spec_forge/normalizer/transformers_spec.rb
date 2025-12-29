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
  end
end
