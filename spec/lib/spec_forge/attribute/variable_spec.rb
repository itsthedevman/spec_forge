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

  #
  # Scenario:
  #
  # A variable is referenced by more than one attribute.
  # When using Templates like {{ var_1 }}, both should resolve to same cached value.
  #
  context "when multiple attributes rely on a single variable" do
    let(:input) { "var_1" }

    let(:variables) do
      # The variable itself is a Faker attribute that generates different values each call
      {var_1: SpecForge::Attribute::Faker.new("faker.string.random")}
    end

    let(:other_attribute) { described_class.new("var_1") }

    context "and #resolved is called" do
      it "is expected to return the same cached value" do
        with_variables(variables) do
          expect(variable.resolved).to eq(other_attribute.resolved)
        end
      end
    end

    context "and #value is called" do
      it "is expected to return different values each time" do
        with_variables(variables) do
          expect(variable.value).not_to eq(other_attribute.value)

          # Just to make sure resolved still works
          expect(variable.resolved).to eq(other_attribute.resolved)
          expect(variable.value).not_to eq(other_attribute.value)
        end
      end
    end
  end

  context "when variables reference other variables" do
    context "and the referenced variable was defined before" do
      let(:variables) do
        {
          var_1: "test_value",
          var_2: SpecForge::Attribute::Variable.new("var_1")
        }
      end

      let(:input) { "var_2" }

      it "is expected to be able to resolve the value" do
        with_variables(variables) do
          expect(variable.resolved).to eq("test_value")
        end
      end
    end

    context "and the reference is circular" do
      let(:variables) do
        {
          var_1: SpecForge::Attribute::Variable.new("var_2"),
          var_2: SpecForge::Attribute::Variable.new("var_1")
        }
      end

      let(:input) { "var_1" }

      it do
        with_variables(variables) do
          expect { variable.resolved }.to raise_error(SystemStackError)
        end
      end
    end
  end
end
