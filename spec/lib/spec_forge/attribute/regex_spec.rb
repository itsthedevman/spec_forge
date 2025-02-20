# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Regex do
  let(:input) {}

  subject(:attribute) { described_class.new(input) }

  describe "#value" do
    subject(:value) { attribute.value }

    context "when it has no flags" do
      let(:input) { "/hello_world/" }

      it do
        expect(value).to be_kind_of(Regexp)
        expect(value.source).to eq("hello_world")
        expect(value.options).to eq(0)
      end
    end

    context "when it has the lowercase flag" do
      let(:input) { "/Test/i" }

      it do
        expect(value).to be_kind_of(Regexp)
        expect(value.source).to eq("Test")
        expect(value.options).to eq(1)
      end
    end

    context "when it has the multiline flag" do
      let(:input) { "/hello\nworld/m" }

      it do
        expect(value).to be_kind_of(Regexp)
        expect(value.source).to eq("hello\nworld")
        expect(value.options).to eq(4)
      end
    end

    context "when it has the extended flag" do
      let(:input) { "/hello_world/x" }

      it do
        expect(value).to be_kind_of(Regexp)
        expect(value.source).to eq("hello_world")
        expect(value.options).to eq(2)
      end
    end

    context "when it has the no encoding flag" do
      let(:input) { "/hello_world/n" }

      it do
        expect(value).to be_kind_of(Regexp)
        expect(value.source).to eq("hello_world")
        expect(value.options).to eq(32)
      end
    end

    context "when it has all flags" do
      let(:input) { "/hello_world/ximn" }

      it do
        expect(value).to be_kind_of(Regexp)
        expect(value.source).to eq("hello_world")
        expect(value.options).to eq(39)
      end
    end
  end
end
