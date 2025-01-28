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

  describe "#value" do
    subject(:value) { described_class.new("").value }

    context "when the method has not been redefined" do
      it "is expected to raise" do
        expect { value }.to raise_error("not implemented")
      end
    end
  end

  describe "#to_proc" do
    let(:attribute) { described_class.new("") }

    subject(:proc) { attribute.to_proc }

    it { is_expected.to be_kind_of(Proc) }

    context "when #value has not been redefined" do
      it "is expected to raise when called" do
        expect { proc.call }.to raise_error("not implemented")
      end
    end

    context "when #value has been redefined" do
      before do
        allow(attribute).to receive(:value).and_return(12345)
      end

      it "is expected to return the value when called" do
        expect(proc.call).to eq(12345)
      end
    end
  end
end
