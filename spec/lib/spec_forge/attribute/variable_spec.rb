# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Variable do
  let(:input) {}
  let(:variables) { {} }

  subject(:variable) do
    variable = described_class.new(input)
    variable.bind_variables(variables)
    variable
  end

  include_examples "from_input_to_attribute" do
    let(:input) { "variables.foobar" }
  end

  context "when just the variable name is referenced" do
    let(:input) { "variable.id" }
    let(:variables) { {id: Faker::String.random} }

    it "is expected to return the value" do
      expect(variable.variable_name).to eq(:id)
      expect(variable.invocation_chain).to eq([])

      expect(variable.value).to eq(variables[:id])
    end
  end

  context "when the variable is a Hash" do
    let(:variables) { {hash: {key_1: Faker::String.random}} }

    context "and the input is for a hash_key" do
      let(:input) { "variable.hash.key_1" }

      it "is expected to return the value" do
        expect(variable.variable_name).to eq(:hash)
        expect(variable.invocation_chain).to eq(["key_1"])

        expect(variable.value).to eq(variables[:hash][:key_1])
      end
    end

    context "and the input is for a method" do
      let(:input) { "variable.hash.size" }

      it "is expected to return the method results" do
        expect(variable.variable_name).to eq(:hash)
        expect(variable.invocation_chain).to eq(["size"])

        expect(variable.value).to eq(variables[:hash].size)
      end
    end

    context "and the input is for an index" do
      let(:input) { "variable.hash.1" }

      it "is expected to raise" do
        expect(variable.variable_name).to eq(:hash)
        expect(variable.invocation_chain).to eq(["1"])

        expect { variable.value }.to raise_error(SpecForge::Error::InvalidInvocationError)
      end
    end
  end

  context "when the variable is an Array" do
    let(:variables) { {array: [1, 2, 3]} }

    context "and the input is for a hash_key" do
      let(:input) { "variable.array.key_1" }

      it "is expected to raise" do
        expect(variable.variable_name).to eq(:array)
        expect(variable.invocation_chain).to eq(["key_1"])

        expect { variable.value }.to raise_error(SpecForge::Error::InvalidInvocationError)
      end
    end

    context "and the input is for a method" do
      let(:input) { "variable.array.size" }

      it "is expected to return the result of the method" do
        expect(variable.variable_name).to eq(:array)
        expect(variable.invocation_chain).to eq(["size"])

        expect(variable.value).to eq(variables[:array].size)
      end
    end

    context "and the input is for an index" do
      context "and it is number index" do
        let(:input) { "variable.array.1" }

        it "is expected to return the value at that index" do
          expect(variable.variable_name).to eq(:array)
          expect(variable.invocation_chain).to eq(["1"])

          expect(variable.value).to eq(variables[:array][1])
        end
      end

      context "and it is a method" do
        let(:input) { "variable.array.second" }

        it "is expected to return the value at that index" do
          expect(variable.variable_name).to eq(:array)
          expect(variable.invocation_chain).to eq(["second"])

          expect(variable.value).to eq(variables[:array].second)
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
      let(:input) { "variable.object.key_1" }

      it "is expected to raise because it is not a valid method" do
        expect(variable.variable_name).to eq(:object)
        expect(variable.invocation_chain).to eq(["key_1"])

        expect { variable.value }.to raise_error(SpecForge::Error::InvalidInvocationError)
      end
    end

    context "and the input is for a method" do
      let(:input) { "variable.object.name" }

      it "is expected to return the result of the method" do
        expect(variable.variable_name).to eq(:object)
        expect(variable.invocation_chain).to eq(["name"])

        expect(variable.value).to eq(variables[:object].name)
      end
    end

    context "and the input is for an index" do
      let(:input) { "variable.object.0" }

      it "is expected to raise because it is not a valid method" do
        expect(variable.variable_name).to eq(:object)
        expect(variable.invocation_chain).to eq(["0"])

        expect { variable.value }.to raise_error(SpecForge::Error::InvalidInvocationError)
      end
    end
  end

  context "when a method does not exist" do
    let(:input) { "variable.object.noop" }
    let(:variables) { {object: Data.define.new} }

    it do
      expect { variable.value }.to raise_error(SpecForge::Error::InvalidInvocationError)
    end
  end

  context "when no variable name is given" do
    let(:input) { "variables." }

    it do
      expect { variable.value }.to raise_error(SpecForge::Error::MissingVariableError)
    end
  end

  context "when there are mixed invocations" do
    let(:input) { "variables.users.first.posts.last.comments.2.author.name" }

    let(:variables) do
      author = Data.define(:name).new(name: Faker::String.random)
      comment = Data.define(:author).new(author:)
      post = Data.define(:comments).new(comments: [comment, comment, comment])
      user = Data.define(:posts).new(posts: [post])

      {users: [user]}
    end

    it "is expected to return the value" do
      expect(variable.value).to eq(
        variables[:users].first.posts.last.comments[2].author.name
      )
    end
  end

  context "when the lookup_table is not a hash" do
    let(:input) { "variable" }
    let(:variables) { nil }

    it do
      expect { variable }.to raise_error(
        SpecForge::Error::InvalidTypeError,
        "Expected Hash, got NilClass for 'variables'"
      )
    end
  end

  #
  # Scenario:
  #
  # A variable is referenced by more than one attribute.
  #
  # ---
  # spec:
  #   variables:
  #     var_1: faker.string.random
  #   expectations:
  #   - body:
  #       body_1: variables.var_1
  #     expect:
  #       json:
  #         json_1: variables.var_1
  # ---
  #
  context "when multiple attributes rely on a single variable" do
    let(:input) { "variables.var_1" }

    let(:variables) do
      SpecForge::Attribute.from(
        var_1: "faker.string.random"
      )
    end

    let(:other_attribute) { described_class.new("variables.var_1").bind_variables(variables) }

    context "and #resolve is called" do
      it "is expected return to the same value" do
        expect(variable.resolved).to eq(other_attribute.resolved)
      end
    end

    context "and #value is called" do
      it "is expected to return different values" do
        expect(variable.value).not_to eq(other_attribute.value)

        # Just to make sure
        expect(variable.resolved).to eq(other_attribute.resolved)
        expect(variable.value).not_to eq(other_attribute.value)
      end
    end
  end

  context "when variables reference themselves" do
    context "and the variable was defined before" do
      let(:variables) do
        variables = SpecForge::Attribute.from({
          var_1: "1",
          var_2: "variables.var_1"
        })

        SpecForge::Attribute.bind_variables(variables, variables)
      end

      let(:input) { "variables.var_2" }

      it "is expected to be able to resolve the value" do
        expect(variable.resolved).to eq("1")
      end
    end

    context "and the variable is defined out of order" do
      let(:variables) do
        variables = SpecForge::Attribute.from({
          var_4: "variables.var_3",
          var_1: "variables.var_5",
          var_3: "variables.var_2",
          var_2: "variables.var_1",
          var_5: "test"
        })

        SpecForge::Attribute.bind_variables(variables, variables)
      end

      let(:input) { "variables.var_4" }

      it "is expected to be able to resolve the value" do
        expect(variable.resolved).to eq("test")
      end
    end

    context "and the reference is circular" do
      let(:variables) do
        variables = SpecForge::Attribute.from({
          var_1: "variables.var_2",
          var_2: "variables.var_1"
        })

        SpecForge::Attribute.bind_variables(variables, variables)
      end

      let(:input) { "variables.var_1" }

      it do
        expect { variable.resolved }.to raise_error(SystemStackError)
      end
    end
  end
end
