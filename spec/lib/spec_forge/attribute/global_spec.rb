# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Global do
  let(:input) { "" }

  subject(:attribute) { described_class.new(input) }

  context "when the namespace is 'variables'" do
    let(:input) { "global.variables.my_global_var" }
    let(:my_global_var) { Faker::String.random }

    before do
      SpecForge.context.global.update(variables: {my_global_var:})
    end

    it "is expected to be able to resolve the global variable" do
      expect(attribute.value).to be_kind_of(SpecForge::Attribute::Variable)
      expect(attribute.resolve).to eq(my_global_var)
    end
  end

  context "when the namespace is not valid" do
    let(:input) { "global.not_defined" }

    it do
      expect { attribute }.to raise_error(
        SpecForge::InvalidGlobalNamespaceError,
        "Invalid global namespace \"not_defined\". Currently supported namespaces are: \"variables\""
      )
    end
  end

  include_examples "from_input_to_attribute" do
    let(:input) { "global.variables.var" }

    before do
      SpecForge.context.global.update(variables: {var: 1})
    end
  end
end
