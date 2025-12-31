# frozen_string_literal: true

RSpec.describe SpecForge::Forge::Runner::ContentValidator do
  describe "#validate!" do
    let(:data) {}
    let(:expected) {}

    subject(:validate!) { described_class.new(data, expected).validate! }

    context "when validating a simple hash" do
      context "when all matchers succeed" do
        let(:data) { {"id" => 42, "name" => "John"} }
        let(:expected) { {"id" => eq(42), "name" => eq("John")} }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end

      context "when a matcher doesn't match" do
        let(:data) { {"id" => 99, "name" => "John"} }
        let(:expected) { {"id" => eq(42), "name" => eq("John")} }

        it "is expected to raise a ContentValidationFailure" do
          expect { validate! }
            .to raise_error(SpecForge::Error::ContentValidationFailure) do |error|
              expect(error.failures.size).to eq(1)
              expect(error.failures.first[:path]).to eq(".id")
              expect(error.failures.first[:message]).to include("expected: 42")
              expect(error.failures.first[:message]).to include("got: 99")
            end
        end
      end

      context "when a key is missing" do
        let(:data) { {"name" => "John"} }
        let(:expected) { {"id" => eq(42), "name" => eq("John")} }

        it "is expected to raise a ContentValidationFailure" do
          expect { validate! }
            .to raise_error(SpecForge::Error::ContentValidationFailure) do |error|
              expect(error.failures.size).to eq(1)
              expect(error.failures.first[:path]).to eq(".id")
              expect(error.failures.first[:message]).to eq("key not found")
            end
        end
      end

      context "when using mixed string and symbol keys" do
        let(:data) { {:id => 42, "name" => "John"} }
        let(:expected) { {"id" => eq(42), :name => eq("John")} }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end
    end

    context "when validating a nested hash" do
      context "when the nested structure matches" do
        let(:data) do
          {
            "user" => {
              "id" => 42,
              "profile" => {"name" => "John"}
            }
          }
        end

        let(:expected) do
          {
            "user" => {
              "id" => eq(42),
              "profile" => {"name" => eq("John")}
            }
          }
        end

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end

      context "when a nested value fails" do
        let(:data) do
          {"user" => {"profile" => {"name" => "Bob"}}}
        end

        let(:expected) do
          {"user" => {"profile" => {"name" => eq("John")}}}
        end

        it "is expected to report the correct path" do
          expect { validate! }
            .to raise_error(SpecForge::Error::ContentValidationFailure) do |error|
              expect(error.failures.first[:path]).to eq(".user.profile.name")
            end
        end
      end
    end

    context "when validating arrays" do
      context "when it is a simple array" do
        let(:data) { [42, "John", true] }
        let(:expected) { [eq(42), be_a(String), be(true)] }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end

      context "when it is an array of objects" do
        let(:data) do
          [
            {"id" => 1, "name" => "Alice"},
            {"id" => 2, "name" => "Bob"}
          ]
        end

        let(:expected) do
          [
            {"id" => be_an(Integer), "name" => be_a(String)},
            {"id" => be_an(Integer), "name" => be_a(String)}
          ]
        end

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end

      context "when an array element fails" do
        let(:data) { [42, 99] }
        let(:expected) { [eq(42), eq(42)] }

        it "is expected to report the correct array index" do
          expect { validate! }
            .to raise_error(SpecForge::Error::ContentValidationFailure) do |error|
              expect(error.failures.first[:path]).to eq("[1]")
            end
        end
      end

      context "when a nested array element fails" do
        let(:data) { [{"id" => 42}, {"id" => 99}] }
        let(:expected) { [{"id" => eq(42)}, {"id" => eq(42)}] }

        it "is expected to report the correct path with array index" do
          expect { validate! }
            .to raise_error(SpecForge::Error::ContentValidationFailure) do |error|
              expect(error.failures.first[:path]).to eq("[1].id")
            end
        end
      end
    end

    context "when validating complex nested structures" do
      context "when the structure is deeply nested with arrays" do
        let(:data) do
          {
            "users" => [
              {"id" => 1, "tags" => ["admin", "active"]},
              {"id" => 2, "tags" => ["user"]}
            ],
            "meta" => {"count" => 2}
          }
        end

        let(:expected) do
          {
            "users" => [
              {"id" => be_an(Integer), "tags" => [be_a(String), be_a(String)]},
              {"id" => be_an(Integer), "tags" => [be_a(String)]}
            ],
            "meta" => {"count" => eq(2)}
          }
        end

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end

      context "when there are multiple failures across the structure" do
        let(:data) do
          {
            "user" => {"id" => "not_number", "name" => 123},
            "posts" => [{"id" => "wrong"}]
          }
        end

        let(:expected) do
          {
            "user" => {"id" => be_an(Integer), "name" => be_a(String)},
            "posts" => [{"id" => be_an(Integer)}]
          }
        end

        it "is expected to collect all failures" do
          expect { validate! }
            .to raise_error(SpecForge::Error::ContentValidationFailure) do |error|
              expect(error.failures.size).to eq(3)

              paths = error.failures.map { |f| f[:path] }
              expect(paths).to contain_exactly(".user.id", ".user.name", ".posts[0].id")
            end
        end
      end
    end

    context "when using different matcher types" do
      context "when using eq matcher" do
        let(:data) { {"value" => 42} }
        let(:expected) { {"value" => eq(42)} }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end

      context "when using include matcher" do
        let(:data) { {"tags" => ["ruby", "rails", "rspec"]} }
        let(:expected) { {"tags" => include("ruby", "rspec")} }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end

      context "when using regex matcher" do
        let(:data) { {"email" => "test@example.com"} }
        let(:expected) { {"email" => match(/@/)} }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end

      context "when using comparison matchers" do
        let(:data) { {"age" => 25} }
        let(:expected) { {"age" => be > 18} }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end

      context "when using be_between matcher" do
        let(:data) { {"score" => 75} }
        let(:expected) { {"score" => be_between(0, 100).inclusive} }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end
    end

    context "when handling edge cases" do
      context "when the hash is empty" do
        let(:data) { {} }
        let(:expected) { {} }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end

      context "when the array is empty" do
        let(:data) { [] }
        let(:expected) { [] }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end

      context "when value is nil and matcher allows it" do
        let(:data) { {"value" => nil} }
        let(:expected) { {"value" => be_nil} }

        it "is expected not to raise an error" do
          expect { validate! }.not_to raise_error
        end
      end

      context "when value is nil but matcher expects a value" do
        let(:data) { {"value" => nil} }
        let(:expected) { {"value" => eq(42)} }

        it "is expected to raise a ContentValidationFailure" do
          expect { validate! }
            .to raise_error(SpecForge::Error::ContentValidationFailure)
        end
      end
    end
  end
end
