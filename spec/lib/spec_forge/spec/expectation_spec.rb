# frozen_string_literal: true

RSpec.describe SpecForge::Spec::Expectation do
  describe "#compile" do
    let(:input) {}
    let(:request) { SpecForge::HTTP::Request.new }

    subject(:expectation) do
      described_class.new(input, "expectation_name")
        .compile(request)
    end

    context "when input is an empty hash" do
      let(:input) { {} }

      it do
        expect { expectation }.to raise_error(
          SpecForge::InvalidTypeError,
          "Expected Hash, got NilClass for 'expect' on expectation"
        )
      end
    end

    context "when input is a valid hash" do
      let(:input) { {expect: {status: 404}} }

      it "is expected to compile" do
        expect(expectation.constraints.status).to eq(404)
      end
    end

    context "when input is not a hash" do
      let(:input) { "" }

      it do
        expect { expectation }.to raise_error(
          SpecForge::InvalidTypeError,
          "Expected Hash, got String for expectation"
        )
      end
    end

    context "when 'name' is provided" do
      let(:input) { {expect: {status: 404}, name: Faker::String.random} }

      it "is expected to rename the expectation" do
        expect(expectation.name).to eq(input[:name])
      end
    end

    context "when 'name' is not provided" do
      let(:input) { {expect: {status: 404}} }

      it "is expected to have the same name" do
        expect(expectation.name).to eq("expectation_name")
      end
    end

    context "when 'variables' is provided" do
      context "and it is a hash" do
        let(:input) { {expect: {status: 404}, variables: {foo: "bar"}} }

        it "is expected to convert the variable attributes" do
          expect(expectation.variables[:foo]).to be_kind_of(SpecForge::Attribute::Literal)
        end
      end

      context "and it not a hash" do
        let(:input) { {expect: {status: 404}, variables: ""} }

        it do
          expect { expectation }.to raise_error(
            SpecForge::InvalidTypeError,
            "Expected Hash, got String for 'variables' on expectation"
          )
        end
      end
    end
  end
end
