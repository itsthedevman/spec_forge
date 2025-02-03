# frozen_string_literal: true

RSpec.describe SpecForge::Spec::Expectation do
  describe "#initialize" do
    let(:input) { {} }
    let(:global_options) { {} }

    subject(:expectation) do
      described_class.new("expectation_name", input, global_options:)
    end

    context "when 'global_options' is provided" do
      let(:input) do
        {
          path: "/users/admin",
          method: "GET",
          content_type: "application/xml",
          query: {
            query_2: 3
          },
          body: {
            body_1: 3
          },
          variables: {
            var_2: 3
          },
          expect: {}
        }
      end

      let(:global_options) do
        {
          path: "/users",
          method: "POST",
          content_type: "application/json",
          query: {
            query_1: 1,
            query_2: 2
          },
          body: {
            body_1: 1,
            body_2: 2
          },
          variables: {
            var_1: 1,
            var_2: 2
          }
        }
      end

      it "is expected to been deeply overwritten by the input" do
      end
    end
  end

  describe "#compile" do
    let(:input) {}

    subject(:expectation) do
      described_class.new("expectation_name", input).compile
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

    context "when 'json' is provided on 'constraints'" do
      context "and it is a hash" do
        let(:input) { {expect: {status: 404, json: {key_1: "faker.number.positive"}}} }

        it "is expected to convert into a constraint" do
          expect(expectation.constraints.status).to eq(404)
          expect(expectation.constraints.json).to be_kind_of(SpecForge::Attribute::Resolvable)
          expect(expectation.constraints.json[:key_1]).to be_kind_of(SpecForge::Attribute::Faker)
        end
      end
    end
  end
end
