# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Parameterized do
  describe ".from_hash" do
    let(:hash) {}

    subject(:attribute) { described_class.from_hash(hash) }

    context "when the macro's value is an array" do
      let(:hash) { {macro: [8]} }

      it "is expected to return an instance that has positional arguments" do
        expect(attribute.arguments).to eq({positional: [8], keyword: {}})
      end
    end

    context "when the macro's value is a hash" do
      let(:hash) { {macro: {code: "NL"}} }

      it "is expected to return an instance that has keyword arguments" do
        expect(attribute.arguments).to eq({positional: [], keyword: {code: "NL"}})
      end
    end

    context "when the macro's value is anything else" do
      let(:hash) { {macro: 1} }

      it "is expected to return an instance that has positional arguments" do
        expect(attribute.arguments).to eq({positional: [1], keyword: {}})
      end
    end

    context "when Attributes are used in arguments" do
      let(:hash) { {macro: ["faker.string.random"]} }

      it "is expected for them to stay as input until `prepare_arguments!` is called" do
        expect(attribute.arguments[:positional]).to include(
          "faker.string.random"
        )

        attribute.send(:prepare_arguments!)

        expect(attribute.arguments[:positional]).to include(
          be_kind_of(SpecForge::Attribute::Faker)
        )
      end
    end
  end
end
