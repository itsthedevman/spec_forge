# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Transform do
  let(:input) { "" }
  let(:positional) { [] }
  let(:keyword) { {} }

  subject(:attribute) { described_class.new(input, positional, keyword) }

  # Note: String concatenation use cases are now handled via string interpolation
  # syntax ({{ }}) rather than transform functions. See tech-spec.md for details.

  context "when the function is not defined" do
    let(:input) { "" }

    it "is expected to raise" do
      expect { attribute }.to raise_error(SpecForge::Error::InvalidTransformFunctionError)
    end
  end

  context "when the function is not supported" do
    let(:input) { "transform.unknown_function" }

    it "is expected to raise" do
      expect { attribute }.to raise_error(SpecForge::Error::InvalidTransformFunctionError)
    end
  end
end
