# frozen_string_literal: true

RSpec.describe SpecForge::Spec::Expectation::Constraint do
  describe "#initialize" do
    let(:status) { 404 }
    let(:json) { {} }

    subject(:constraint) do
      described_class.new(
        status: SpecForge::Attribute.from(status),
        json: SpecForge::Attribute.from(json)
      )
    end

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

    describe "#resolve" do
      let(:json) { {var_1: 1, var_2: "2"} }

      subject(:resolved) { constraint.resolve }

      it "is expected to resolve all constraints as a hash" do
        expect(resolved).to be_kind_of(Hash)
        expect(resolved[:status]).to be_kind_of(Integer).and(eq(404))
        expect(resolved[:json]).to be_kind_of(Hash)

        expect(resolved[:json]["var_1"]).to be_kind_of(RSpec::Matchers::BuiltIn::Eq)
        expect(resolved[:json]["var_2"]).to be_kind_of(RSpec::Matchers::BuiltIn::Eq)
      end
    end
  end
end
