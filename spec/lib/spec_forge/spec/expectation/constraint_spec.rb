# frozen_string_literal: true

RSpec.describe SpecForge::Spec::Expectation::Constraint do
  let(:status) { 404 }
  let(:json) { {} }

  subject(:constraint) do
    described_class.new(
      status: SpecForge::Attribute.from(status),
      json: SpecForge::Attribute.from(json)
    )
  end

  describe "#initialize" do
    context "when 'status' is provided" do
      let(:status) { 404 }

      it "is expected to store the status as an integer" do
        expect(constraint.status).to eq(404)
        expect(constraint.status).to be_kind_of(SpecForge::Attribute::Literal)
      end
    end

    context "when 'json' is provided" do
      let(:json) { {foo: "faker.string.random"} }

      it "is expected to covert the json attributes" do
        expect(constraint.json[:foo]).to be_kind_of(SpecForge::Attribute::Faker)
      end
    end
  end
end
