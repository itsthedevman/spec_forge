# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Matcher do
  let(:input) { "" }
  let(:positional) { [] }
  let(:keyword) { {} }

  subject(:attribute) { described_class.new(input, positional, keyword) }

  describe "KEYWORD_REGEX" do
    subject(:regex) { described_class::KEYWORD_REGEX }

    context "when the input starts with 'matcher'" do
      let(:input) { "matcher.include" }

      it { expect(input).to match(regex) }
    end

    context "when the input starts with 'be'" do
      let(:input) { "be.nil" }

      it { expect(input).to match(regex) }
    end

    context "when the input starts with 'kind_of'" do
      let(:input) { "kind_of.integer" }

      it { expect(input).to match(regex) }
    end
  end

  describe "#initialize" do
    context "when the input starts with 'matcher'" do
      context "and the matcher does not exist" do
        let(:input) { "matcher.does_not_exist" }

        it do
          expect { attribute }.to raise_error(NameError)
        end
      end

      context "and the matcher exists" do
        let(:input) { "matcher.contain_exactly" }
        let(:positional) { [1] }

        it "is expected to find the matcher" do
          expect(attribute.matcher_method).to be_kind_of(UnboundMethod)
          expect(attribute.matcher_method.name).to eq(:contain_exactly)
          expect(attribute.arguments[:positional]).to eq([1])
        end
      end
    end

    context "when the starts with 'kind_of'" do
      context "and the matcher does not exist"
      context "and the matcher exists"
    end

    context "when the starts with 'be'" do
      context "and the matcher does not exist"
      context "and the matcher exists"

      context "and the matcher is 'nil'"
      context "and the matcher is 'greater_than'"
      context "and the matcher is 'greater_than_or_equal'"
      context "and the matcher is 'greater'"
      context "and the matcher is 'greater_or_equal'"
      context "and the matcher is 'less_than'"
      context "and the matcher is 'less_than_or_equal'"
      context "and the matcher is 'less'"
      context "and the matcher is 'less_or_equal'"
    end
  end
end
