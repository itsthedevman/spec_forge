# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Variable do
  let(:input) {}
  let(:variables) { {} }

  subject(:variable) { described_class.new(input).update_variable_value!(variables) }

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

        expect { variable.value }.to raise_error(SpecForge::InvalidInvocationError)
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

        expect { variable.value }.to raise_error(SpecForge::InvalidInvocationError)
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

        expect { variable.value }.to raise_error(SpecForge::InvalidInvocationError)
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

        expect { variable.value }.to raise_error(SpecForge::InvalidInvocationError)
      end
    end
  end

  context "when a method does not exist" do
    let(:input) { "variable.object.noop" }
    let(:variables) { {object: Data.define.new} }

    it do
      expect { variable.value }.to raise_error(SpecForge::InvalidInvocationError)
    end
  end

  context "when no variable name is given" do
    let(:input) { "variable." }

    it do
      expect { variable.value }.to raise_error(SpecForge::MissingVariableError)
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
        SpecForge::InvalidTypeError,
        "Expected Hash, got NilClass for 'variables'"
      )
    end
  end
end
