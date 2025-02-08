# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Factory do
  let(:input) { "" }
  let(:positional) { [] }
  let(:keyword) { {} }

  subject(:factory) { described_class.new(input, positional:, keyword:) }

  before do
    stub_const(
      "User",
      Class.new do
        attr_accessor :name

        def save!
          true
        end
      end
    )

    SpecForge::Factory.new(name: :user, model_class: "User", attributes: {name: "Bob"}).register
  end

  context "when just the factory name is referenced" do
    let(:input) { "factories.user" }

    it "is expected to store and return the result of the factory" do
      expect(factory.factory_name).to eq(:user)
      expect(factory.value).to be_kind_of(User)
    end
  end

  context "when the result is chained"

  context "when the expanded form is used" do
    context "and 'attributes' is provided"
    context "and 'strategy' is provided"
  end
end
