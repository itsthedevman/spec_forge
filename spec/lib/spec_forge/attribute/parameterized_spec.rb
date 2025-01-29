# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Parameterized do
  describe ".from_hash" do
    let(:hash) {}

    subject(:attribute) { described_class.from_hash(hash) }

    context "when the macro has no arguments" do
      let(:hash) { {input: ""} }

      it "is expected to return an instance that has no arguments" do
        expect(attribute.arguments).to eq({positional: [], keyword: {}})
      end
    end

    context "when the macro has positional arguments" do
      let(:hash) { {input: [8]} }

      it "is expected to return an instance that has positional arguments" do
        expect(attribute.arguments).to eq({positional: [8], keyword: {}})
      end
    end

    context "when the macro has keyword arguments" do
      let(:hash) { {input: {code: "NL"}} }

      it "is expected to return an instance that has positional arguments" do
        expect(attribute.arguments).to eq({positional: [], keyword: {code: "NL"}})
      end
    end
  end
end
