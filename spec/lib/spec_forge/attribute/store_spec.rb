# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Store do
  let(:input) {}

  subject(:attribute) { described_class.new(input) }

  include_examples "from_input_to_attribute" do
    let(:input) { "store.foobar" }
  end

  context "when the entry exists" do
    let(:id) { SecureRandom.uuid }
    let(:input) { "store.#{id}.variables.test" }

    before do
      SpecForge.context.store.set(
        id,
        scope: :spec,
        request: {},
        variables: {
          test: 1
        },
        response: {}
      )
    end

    it "is expected to return the value" do
      expect(SpecForge.context.store.size).to eq(1)
      expect(attribute.resolve).to eq(1)
    end
  end

  context "when the entry that does not exist is referenced" do
    let!(:input) { "store.does_not_exist.id" }

    it do
      expect { attribute.resolve }.to raise_error(SpecForge::Error::InvalidInvocationError)
    end
  end
end
