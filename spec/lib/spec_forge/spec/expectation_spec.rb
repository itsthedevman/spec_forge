# frozen_string_literal: true

RSpec.describe SpecForge::Spec::Expectation do
  describe "#compile" do
    let(:input) {}
    let(:request) { SpecForge::Request.new }

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
          expect(expectation.variables).to be_kind_of(ActiveSupport::HashWithIndifferentAccess)
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

    context "when 'body' is provided" do
      context "and it is a hash" do
        let(:request) do
          SpecForge::Request.new(body: {name: "Bob", email: "faker.internet.email"})
        end

        let(:input) { {expect: {status: 404}, body: {name: "Billy"}} }

        it "is expected to clone the request and convert the body attributes" do
          expect(expectation.request.body[:name]).to eq("Billy")
          expect(request.body[:name]).to eq("Bob")
        end
      end

      context "and it not a hash" do
        let(:input) { {expect: {status: 404}, body: ""} }

        it do
          expect { expectation }.to raise_error(
            SpecForge::InvalidTypeError,
            "Expected Hash, got String for 'body'"
          )
        end
      end
    end

    context "when 'body' is not provided" do
      let(:input) { {expect: {status: 404}} }

      it "is defaulted to an empty hash" do
        expect(expectation.body).to eq({})
      end
    end

    context "when 'query' is provided" do
      context "and it is a hash" do
        let(:request) do
          SpecForge::Request.new(query: {id: 1})
        end

        let(:input) { {expect: {status: 404}, query: {id: 2}} }

        it "is expected to clone the request and convert the body attributes" do
          expect(expectation.request.query[:id]).to eq(2)
          expect(request.query[:id]).to eq(1)
        end
      end

      context "and it not a hash" do
        let(:input) { {expect: {status: 404}, query: ""} }

        it do
          expect { expectation }.to raise_error(
            SpecForge::InvalidTypeError,
            "Expected Hash, got String for 'query'"
          )
        end
      end
    end

    context "when 'query' is not provided" do
      let(:input) { {expect: {status: 404}} }

      it "is defaulted to an empty hash" do
        expect(expectation.query).to eq({})
      end
    end

    context "when 'params' is provided as an alias" do
      let(:input) { {expect: {status: 404}, params: {id: 2}} }

      it "is expected to clone the request and convert the body attributes" do
        expect(expectation.query[:id]).to eq(2)
      end
    end
  end
end
