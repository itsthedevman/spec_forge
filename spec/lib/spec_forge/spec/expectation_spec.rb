# frozen_string_literal: true

RSpec.describe SpecForge::Spec::Expectation do
  describe "#initialize" do
    let(:input) { {} }

    subject(:expectation) do
      described_class.new(**Generator.empty_expectation_hash.merge(input))
    end

    context "when 'status' is provided on 'expect'" do
      let(:input) { {expect: {status: 404}} }

      it "is expected to compile" do
        expect(expectation.constraints.status).to eq(404)
      end
    end

    context "when 'json' is provided on 'expect'" do
      let(:input) { {expect: {status: 404, json: {key_1: "faker.number.positive"}}} }

      it "is expected to convert into a constraint" do
        expect(expectation.constraints).to be_kind_of(described_class::Constraint)
      end
    end
  end
end
