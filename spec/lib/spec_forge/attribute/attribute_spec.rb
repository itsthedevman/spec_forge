# frozen_string_literal: true

RSpec.describe SpecForge::Attribute do
  describe ".from" do
    let(:input) {}

    subject(:attribute) { described_class.from(input) }

    context "when the input is a String" do
      context "and it is a valid faker macro" do
        let(:input) { "faker.number.positive" }

        it { is_expected.to be_kind_of(described_class::Faker) }
      end

      context "and it is a valid faker macro, but in mixed caps" do
        let(:input) { "FAkEr.nUMBEr.positIVe" }

        it { is_expected.to be_kind_of(described_class::Faker) }
      end

      context "and it is a misspelled faker macro" do
        let(:input) { "fakeer.number.positive" }

        it { is_expected.to be_kind_of(described_class::Literal) }
      end

      # context "and it is the transform macro"
      # context "and it is the variable macro"
      # context "and it is the factory macro"

      context "and it is literally anything else" do
        let(:input) { "literally anything else" }

        it { is_expected.to be_kind_of(described_class::Literal) }
      end
    end

    context "when the input is a Boolean" do
      let(:input) { true }

      it { is_expected.to be_kind_of(described_class::Literal) }
    end

    context "when the input is a Hash"
    context "when the input is an Array"
  end
end
