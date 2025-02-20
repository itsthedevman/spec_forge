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

      it "is expected to convert the json attributes" do
        expect(constraint.json[:foo]).to be_kind_of(SpecForge::Attribute::Faker)
      end
    end

    context "when 'json' has matchers" do
      let(:json) do
        {foo: "/testing/i", bar: "bar", baz: SpecForge::Attribute.from("kind_of.string")}
      end

      it "is expected to convert the json attributes" do
        expect(constraint.json[:foo].resolve).to be_kind_of(RSpec::Matchers::BuiltIn::Match)
        expect(constraint.json[:bar].resolve).to be_kind_of(RSpec::Matchers::BuiltIn::Eq)
        expect(constraint.json[:baz].resolve).to be_kind_of(RSpec::Matchers::BuiltIn::BeAKindOf)
      end
    end
  end
end
