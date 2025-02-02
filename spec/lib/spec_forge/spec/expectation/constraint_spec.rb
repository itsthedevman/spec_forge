# frozen_string_literal: true

RSpec.describe SpecForge::Spec::Expectation::Constraint do
  describe "#initialize" do
    let(:status) { 404 }
    let(:json) {}

    subject(:constraint) do
      described_class.new(
        status: SpecForge::Attribute.from(status),
        json: SpecForge::Attribute.from(json)
      )
    end

    context "when 'status' is provided" do
      context "and it is a string" do
        let(:status) { "404" }

        it "is expected to convert the status to an integer" do
          expect(constraint.status).to eq(404)
        end
      end

      context "and it is a integer" do
        let(:status) { 404 }

        it "is expected to store the status as an integer" do
          expect(constraint.status).to eq(404)
        end
      end

      context "and it is not a string or integer" do
        let(:status) { [] }

        it do
          expect { constraint }.to raise_error(
            SpecForge::InvalidTypeError,
            "Expected Integer | String, got Array for 'status' on constraint"
          )
        end
      end
    end

    context "when 'json' is provided" do
      context "and it is a hash" do
        let(:json) { {foo: "faker.string.random"} }

        it "is expected to cover the json attributes" do
          expect(constraint.json[:foo]).to be_kind_of(SpecForge::Attribute::Faker)
        end
      end

      context "and it not a hash" do
        let(:json) { "" }

        it do
          expect { constraint }.to raise_error(
            SpecForge::InvalidTypeError,
            "Expected Hash, got String for 'json' on constraint"
          )
        end
      end
    end

    context "when 'json' is not provided" do
      it "is defaulted to an empty hash" do
        expect(constraint.json).to eq({})
      end
    end
  end
end
