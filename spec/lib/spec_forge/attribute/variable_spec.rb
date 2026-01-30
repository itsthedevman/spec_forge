# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Variable do
  let(:input) {}
  let(:variables) { {} }

  # Helper to create a Forge context with the given variables
  def with_variables(vars, &block)
    forge_variables = SpecForge::Forge::Variables.new(static: vars)
    context = SpecForge::Forge::Context.new(variables: forge_variables)
    SpecForge::Forge.with_context(context, &block)
  end

  subject(:variable) { described_class.new(input) }

  # Note: Variables are no longer created via Attribute.from("variables.x")
  # They are created internally by Template when processing {{ variable_name }}
  # So we test Variable directly, not through Attribute.from

  context "when just the variable name is referenced" do
    context "and the variable is set via context" do
      let(:input) { "id" }
      let(:variables) { {id: Faker::String.random} }

      it "is expected to return the value" do
        expect(variable.variable_name).to eq(:id)
        expect(variable.invocation_chain).to eq([])

        with_variables(variables) do
          expect(variable.value).to eq(variables[:id])
        end
      end
    end

    context "and the variable contains nested data" do
      let(:input) { "user_data" }
      let(:variables) { {user_data: {id: 123, name: "Test"}} }

      it "is expected to return the value" do
        with_variables(variables) do
          expect(variable.value).to eq(variables[:user_data])
        end
      end
    end
  end

  context "when the variable is a Hash" do
    let(:variables) { {hash: {key_1: Faker::String.random}} }

    context "and the input is for a hash_key" do
      let(:input) { "hash.key_1" }

      it "is expected to return the value" do
        expect(variable.variable_name).to eq(:hash)
        expect(variable.invocation_chain).to eq(["key_1"])

        with_variables(variables) do
          expect(variable.value).to eq(variables[:hash][:key_1])
        end
      end
    end

    context "and the input is for a method" do
      let(:input) { "hash.size" }

      it "is expected to return the method results" do
        expect(variable.variable_name).to eq(:hash)
        expect(variable.invocation_chain).to eq(["size"])

        with_variables(variables) do
          expect(variable.value).to eq(variables[:hash].size)
        end
      end
    end

    context "and the input is for an index" do
      let(:input) { "hash.1" }

      it "is expected to raise" do
        expect(variable.variable_name).to eq(:hash)
        expect(variable.invocation_chain).to eq(["1"])

        with_variables(variables) do
          expect { variable.value }.to raise_error(SpecForge::Error::InvalidInvocationError)
        end
      end
    end
  end

  context "when the variable is an Array" do
    let(:variables) { {array: [1, 2, 3]} }

    context "and the input is for a hash_key" do
      let(:input) { "array.key_1" }

      it "is expected to raise" do
        expect(variable.variable_name).to eq(:array)
        expect(variable.invocation_chain).to eq(["key_1"])

        with_variables(variables) do
          expect { variable.value }.to raise_error(SpecForge::Error::InvalidInvocationError)
        end
      end
    end

    context "and the input is for a method" do
      let(:input) { "array.size" }

      it "is expected to return the result of the method" do
        expect(variable.variable_name).to eq(:array)
        expect(variable.invocation_chain).to eq(["size"])

        with_variables(variables) do
          expect(variable.value).to eq(variables[:array].size)
        end
      end
    end

    context "and the input is for an index" do
      context "and it is number index" do
        let(:input) { "array.1" }

        it "is expected to return the value at that index" do
          expect(variable.variable_name).to eq(:array)
          expect(variable.invocation_chain).to eq(["1"])

          with_variables(variables) do
            expect(variable.value).to eq(variables[:array][1])
          end
        end
      end

      context "and it is a method" do
        let(:input) { "array.second" }

        it "is expected to return the value at that index" do
          expect(variable.variable_name).to eq(:array)
          expect(variable.invocation_chain).to eq(["second"])

          with_variables(variables) do
            expect(variable.value).to eq(variables[:array].second)
          end
        end
      end
    end
  end

  context "when the variable is an object" do
    let(:variables) do
      {
        object: Data.define(:name).new(name: Faker::String.random)
      }
    end

    context "and the input is for a hash_key" do
      let(:input) { "object.key_1" }

      it "is expected to raise because it is not a valid method" do
        expect(variable.variable_name).to eq(:object)
        expect(variable.invocation_chain).to eq(["key_1"])

        with_variables(variables) do
          expect { variable.value }.to raise_error(SpecForge::Error::InvalidInvocationError)
        end
      end
    end

    context "and the input is for a method" do
      let(:input) { "object.name" }

      it "is expected to return the result of the method" do
        expect(variable.variable_name).to eq(:object)
        expect(variable.invocation_chain).to eq(["name"])

        with_variables(variables) do
          expect(variable.value).to eq(variables[:object].name)
        end
      end
    end

    context "and the input is for an index" do
      let(:input) { "object.0" }

      it "is expected to raise because it is not a valid method" do
        expect(variable.variable_name).to eq(:object)
        expect(variable.invocation_chain).to eq(["0"])

        with_variables(variables) do
          expect { variable.value }.to raise_error(SpecForge::Error::InvalidInvocationError)
        end
      end
    end
  end

  context "when a method does not exist" do
    let(:input) { "object.noop" }
    let(:variables) { {object: Data.define.new} }

    it do
      with_variables(variables) do
        expect { variable.value }.to raise_error(SpecForge::Error::InvalidInvocationError)
      end
    end
  end

  context "when the variable does not exist in context" do
    let(:input) { "missing" }

    it do
      with_variables({}) do
        expect { variable.value }.to raise_error(SpecForge::Error::MissingVariableError)
      end
    end
  end

  context "when there are mixed invocations" do
    let(:input) { "users.first.posts.last.comments.2.author.name" }

    let(:variables) do
      author = Data.define(:name).new(name: Faker::String.random)
      comment = Data.define(:author).new(author:)
      post = Data.define(:comments).new(comments: [comment, comment, comment])
      user = Data.define(:posts).new(posts: [post])

      {users: [user]}
    end

    it "is expected to return the value" do
      with_variables(variables) do
        expect(variable.value).to eq(
          variables[:users].first.posts.last.comments[2].author.name
        )
      end
    end
  end

  context "when accessing deeply nested response body data" do
    let(:input) { "response.body.users.0.profile.settings.notifications.email" }

    let(:variables) do
      {
        response: {
          status: 200,
          headers: {"content-type" => "application/json"},
          body: {
            "users" => [
              {
                "id" => 1,
                "profile" => {
                  "settings" => {
                    "notifications" => {
                      "email" => true,
                      "sms" => false
                    }
                  }
                }
              }
            ]
          }
        }
      }
    end

    it "is expected to resolve the deeply nested value" do
      with_variables(variables) do
        expect(variable.value).to be(true)
      end
    end
  end

  describe "custom context" do
    context "when a custom context is provided via options" do
      let(:input) { "my_var" }
      let(:custom_context) { {my_var: "custom_value"} }

      subject(:variable) { described_class.new(input, context: custom_context) }

      it "uses the custom context instead of Forge.context" do
        # No Forge context needed - custom context is used
        expect(variable.value).to eq("custom_value")
      end

      it "takes precedence over Forge.context" do
        forge_variables = {my_var: "forge_value"}

        with_variables(forge_variables) do
          # Custom context should win
          expect(variable.value).to eq("custom_value")
        end
      end
    end

    context "when custom context contains Attribute objects" do
      let(:input) { "dynamic_var" }
      let(:custom_context) do
        {
          dynamic_var: SpecForge::Attribute::Faker.new("faker.number.between", keyword: {from: 1, to: 100000})
        }
      end

      subject(:variable) { described_class.new(input, context: custom_context) }

      it "resolves the Attribute on each access" do
        first_value = variable.value
        second_value = variable.value

        expect(first_value).to be_a(Integer)
        expect(second_value).to be_a(Integer)
        expect(first_value).to be_between(1, 100000)
        expect(second_value).to be_between(1, 100000)
      end
    end

    context "when custom context variables reference each other" do
      let(:input) { "greeting" }
      let(:custom_context) do
        {
          name: SpecForge::Attribute::Literal.new("World"),
          greeting: SpecForge::Attribute::Template.new("Hello, {{ name }}!", context: nil)
        }
      end

      before do
        # The greeting template needs access to the same context
        custom_context[:greeting] = SpecForge::Attribute::Template.new(
          "Hello, {{ name }}!",
          context: custom_context
        )
      end

      subject(:variable) { described_class.new(input, context: custom_context) }

      it "resolves the variable chain" do
        expect(variable.value).to eq("Hello, World!")
      end
    end

    context "when variable is missing from custom context" do
      let(:input) { "missing_var" }
      let(:custom_context) { {other_var: "value"} }

      subject(:variable) { described_class.new(input, context: custom_context) }

      it "raises MissingVariableError" do
        expect { variable.value }.to raise_error(SpecForge::Error::MissingVariableError)
      end
    end

    context "when custom context is empty" do
      let(:input) { "any_var" }
      let(:custom_context) { {} }

      subject(:variable) { described_class.new(input, context: custom_context) }

      it "raises MissingVariableError" do
        expect { variable.value }.to raise_error(SpecForge::Error::MissingVariableError)
      end
    end
  end
end
