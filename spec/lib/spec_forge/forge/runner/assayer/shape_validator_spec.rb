# frozen_string_literal: true

RSpec.describe SpecForge::Forge::Runner::Assayer::ShapeValidator do
  let(:schema) {}
  let(:data) {}

  subject(:validate) { described_class.new(data, schema).validate! }

  describe "valid data" do
    context "when it is a flat hash" do
      let(:schema) do
        {
          type: [Hash],
          structure: {
            id: {type: [Integer]},
            email: {type: [String]},
            active: {type: [TrueClass, FalseClass]}
          }
        }
      end

      let(:data) do
        {
          id: Faker::Number.number(digits: 10),
          email: Faker::Internet.email,
          active: Faker::Boolean.boolean
        }
      end

      it "is expected not to raise an error" do
        expect { validate }.not_to raise_error
      end
    end

    context "when it has a nested hash" do
      let(:schema) do
        {
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
        }
      end

      let(:data) do
        {
          id: 123,
          user: {
            name: "John",
            role: "admin"
          }
        }
      end

      it "is expected not to raise an error" do
        expect { validate }.not_to raise_error
      end

      context "when the optional field is nil" do
        let(:data) do
          {
            id: 123,
            user: {
              name: "John",
              role: nil
            }
          }
        end

        it "is expected not to raise an error" do
          expect { validate }.not_to raise_error
        end
      end
    end

    context "when it is an array of objects" do
      let(:schema) do
        {
          type: [Array],
          pattern: {
            type: [Hash],
            structure: {
              id: {type: [Integer]},
              name: {type: [String]}
            }
          }
        }
      end

      let(:data) do
        [
          {id: 1, name: "First"},
          {id: 2, name: "Second"},
          {id: 3, name: "Third"}
        ]
      end

      it "is expected not to raise an error" do
        expect { validate }.not_to raise_error
      end
    end

    context "when it is an array of primitives" do
      let(:schema) do
        {
          type: [Hash],
          structure: {
            tags: {
              type: [Array],
              pattern: {type: [String]}
            }
          }
        }
      end

      let(:data) do
        {tags: ["ruby", "rspec", "testing"]}
      end

      it "is expected not to raise an error" do
        expect { validate }.not_to raise_error
      end
    end

    context "when it is a nested array" do
      let(:schema) do
        {
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
        }
      end

      let(:data) do
        [
          {
            id: 1,
            title: "Issue 1",
            user: {login: "user1"},
            labels: [
              {name: "bug", color: "red"},
              {name: "urgent", color: "orange"}
            ]
          },
          {
            id: 2,
            title: "Issue 2",
            user: {login: "user2"},
            labels: []
          }
        ]
      end

      it "is expected not to raise an error" do
        expect { validate }.not_to raise_error
      end
    end

    context "when it is a top-level primitive" do
      let(:schema) { {type: [String]} }
      let(:data) { "hello world" }

      it "is expected not to raise an error" do
        expect { validate }.not_to raise_error
      end
    end

    context "when it is an empty hash" do
      let(:schema) { {type: [Hash], structure: {}} }
      let(:data) { {} }

      it "is expected not to raise an error" do
        expect { validate }.not_to raise_error
      end
    end

    context "when it is an empty array" do
      let(:schema) { {type: [Array]} }
      let(:data) { [] }

      it "is expected not to raise an error" do
        expect { validate }.not_to raise_error
      end
    end

    context "when it is a multi-element array (tuple)" do
      let(:schema) do
        {
          type: [Array],
          structure: [
            {type: [Hash], structure: {id: {type: [Integer]}}},
            {type: [Hash], structure: {name: {type: [String]}}}
          ]
        }
      end

      let(:data) do
        [
          {id: 42},
          {name: "test"}
        ]
      end

      it "is expected not to raise an error" do
        expect { validate }.not_to raise_error
      end
    end

    context "when it has nested arrays of primitives" do
      let(:schema) do
        {
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
        }
      end

      let(:data) do
        {
          matrix: [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9]
          ]
        }
      end

      it "is expected not to raise an error" do
        expect { validate }.not_to raise_error
      end
    end
  end

  describe "invalid data" do
    context "when the top-level type is wrong" do
      let(:schema) { {type: [Hash]} }
      let(:data) { "not a hash" }

      it "is expected to raise a ShapeValidationFailure" do
        expect { validate }.to raise_error(SpecForge::Error::ShapeValidationFailure)
      end
    end

    context "when a field has the wrong type" do
      let(:schema) do
        {
          type: [Hash],
          structure: {
            id: {type: [Integer]},
            name: {type: [String]}
          }
        }
      end

      let(:data) do
        {id: "not an integer", name: "valid"}
      end

      it "is expected to raise a ShapeValidationFailure" do
        expect { validate }.to raise_error(SpecForge::Error::ShapeValidationFailure)
      end
    end

    context "when a required field is missing" do
      let(:schema) do
        {
          type: [Hash],
          structure: {
            id: {type: [Integer]},
            name: {type: [String]}
          }
        }
      end

      let(:data) do
        {id: 123}
      end

      it "is expected to raise a ShapeValidationFailure" do
        expect { validate }.to raise_error(SpecForge::Error::ShapeValidationFailure)
      end
    end

    context "when a nested hash has the wrong type" do
      let(:schema) do
        {
          type: [Hash],
          structure: {
            user: {
              type: [Hash],
              structure: {
                name: {type: [String]}
              }
            }
          }
        }
      end

      let(:data) do
        {user: "not a hash"}
      end

      it "is expected to raise a ShapeValidationFailure" do
        expect { validate }.to raise_error(SpecForge::Error::ShapeValidationFailure)
      end
    end

    context "when an array element has the wrong type" do
      let(:schema) do
        {
          type: [Array],
          pattern: {type: [Integer]}
        }
      end

      let(:data) do
        [1, 2, "three", 4]
      end

      it "is expected to raise a ShapeValidationFailure" do
        expect { validate }.to raise_error(SpecForge::Error::ShapeValidationFailure)
      end
    end

    context "when an array of objects has a field with the wrong type" do
      let(:schema) do
        {
          type: [Array],
          pattern: {
            type: [Hash],
            structure: {
              id: {type: [Integer]},
              name: {type: [String]}
            }
          }
        }
      end

      let(:data) do
        [
          {id: 1, name: "valid"},
          {id: "invalid", name: "also valid"},
          {id: 3, name: "still valid"}
        ]
      end

      it "is expected to raise a ShapeValidationFailure" do
        expect { validate }.to raise_error(SpecForge::Error::ShapeValidationFailure)
      end
    end

    context "when a deeply nested array element has the wrong type" do
      let(:schema) do
        {
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
        }
      end

      let(:data) do
        {
          matrix: [
            [1, 2, 3],
            [4, "five", 6],
            [7, 8, 9]
          ]
        }
      end

      it "is expected to raise a ShapeValidationFailure" do
        expect { validate }.to raise_error(SpecForge::Error::ShapeValidationFailure)
      end
    end

    context "when multiple fields have wrong types" do
      let(:schema) do
        {
          type: [Hash],
          structure: {
            id: {type: [Integer]},
            name: {type: [String]},
            active: {type: [TrueClass, FalseClass]}
          }
        }
      end

      let(:data) do
        {id: "wrong", name: 123, active: "also wrong"}
      end

      it "is expected to raise a ShapeValidationFailure" do
        expect { validate }.to raise_error(SpecForge::Error::ShapeValidationFailure)
      end
    end

    context "when a tuple element has the wrong structure" do
      let(:schema) do
        {
          type: [Array],
          structure: [
            {type: [Hash], structure: {id: {type: [Integer]}}},
            {type: [Hash], structure: {name: {type: [String]}}}
          ]
        }
      end

      let(:data) do
        [
          {id: "not an integer"},
          {name: "valid"}
        ]
      end

      it "is expected to raise a ShapeValidationFailure" do
        expect { validate }.to raise_error(SpecForge::Error::ShapeValidationFailure)
      end
    end
  end
end
