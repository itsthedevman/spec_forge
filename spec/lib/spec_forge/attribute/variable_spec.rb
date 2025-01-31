# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Variable do
  let(:input) {}
  let(:variables) {}

  subject(:variable) { described_class.new(input).update_lookup_table(variables) }

  context "when just the variable name is referenced" do
    let(:input) { "variables.id" }
    let(:variables) { {id: Faker::String.random} }

    it "is expected to return the value" do
      expect(variable.variable_name).to eq("id")
      expect(variable.invocation_chain).to eq([])

      expect(variable.value).to eq(variables[:id])
    end
  end

  context "when the variable is a Hash" do
    let(:variables) { {hash: {key_1: Faker::String.random}} }

    context "and the input is for a hash_key" do
      let(:input) { "variables.hash.key_1" }

      it "is expected to return the value" do
        expect(variable.variable_name).to eq("hash")
        expect(variable.invocation_chain).to eq(["key_1"])

        expect(variable.value).to eq(variables[:hash][:key_1])
      end
    end

    context "and the input is for a method" do
      let(:input) { "variables.hash.size" }

      it "is expected to return the method results" do
        expect(variable.variable_name).to eq("hash")
        expect(variable.invocation_chain).to eq(["size"])

        expect(variable.value).to eq(variables[:hash].size)
      end
    end

    context "and the input is for an index" do
      let(:input) { "variables.hash.1" }

      it "is expected to raise" do
        expect(variable.variable_name).to eq("hash")
        expect(variable.invocation_chain).to eq(["1"])

        expect { variable.value }.to raise_error(
          InvalidInvocationError,
          "\"1\" is not a valid key, method, or index for Hash"
        )
      end
    end
  end

  context "when the variable is an Array"
  context "when no variable name is given"
  context "when there are mixed invocations"
end
