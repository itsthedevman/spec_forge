# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Literal do
  let(:input) {}

  subject(:attribute) { described_class.new(input) }

  describe "#value" do
    subject(:value) { attribute.value }

    context "when input is a string" do
      let(:input) { Faker::String.random }

      it "is expected to return the exact value" do
        expect(value).to eq(input)
      end
    end

    context "when input is a integer" do
      let(:input) { Faker::Number.positive.to_i }

      it "is expected to return the exact value" do
        expect(value).to eq(input)
      end
    end

    context "when input is a float" do
      let(:input) { Faker::Number.positive.to_f }

      it "is expected to return the exact value" do
        expect(value).to eq(input)
      end
    end

    context "when input is a boolean" do
      let(:input) { Faker::Boolean.boolean }

      it "is expected to return the exact value" do
        expect(value).to eq(input)
      end
    end

    context "when input is an array" do
      let(:input) { [1] }

      it "is expected to return the exact value" do
        expect(value).to eq([described_class.new(1)])
      end
    end

    context "when input is a hash" do
      let(:input) { {foo: "bar"} }

      it "is expected to return the exact value" do
        expect(value).to eq(input)
      end
    end

    context "when input is a string and it has regex like syntax" do
      context "and it is empty" do
        let(:input) { "//" }

        it { expect(value).to be_kind_of(String) }
      end

      context "and it has no flags" do
        let(:input) { "/hello_world/" }

        it { expect(value).to be_kind_of(Regexp) }
      end

      context "and it has the lowercase flag" do
        let(:input) { "/hello_world/i" }

        it { expect(value).to be_kind_of(Regexp) }
      end

      context "and it has the multiline flag" do
        let(:input) { "/hello_world/m" }

        it { expect(value).to be_kind_of(Regexp) }
      end

      context "and it has the extended flag" do
        let(:input) { "/hello_world/x" }

        it { expect(value).to be_kind_of(Regexp) }
      end

      context "and it has the no encoding flag" do
        let(:input) { "/hello_world/n" }

        it { expect(value).to be_kind_of(Regexp) }
      end

      context "and it has all flags" do
        let(:input) { "/hello_world/ximn" }

        it { expect(value).to be_kind_of(Regexp) }
      end
    end
  end
end
