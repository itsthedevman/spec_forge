# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Resolvable do
  let(:object) {}

  subject(:resolvable) { described_class.new(object) }

  describe "#resolve" do
    it { expect(resolvable).to respond_to(:resolve) }

    context "when the object is an array" do
      let(:object) do
        [
          SpecForge::Attribute.from(1),
          SpecForge::Attribute.from([
            "faker.string.random",
            "faker.number.positive"
          ])
        ]
      end

      it "recursively resolves the array" do
        expect(resolvable.resolve).to match([1, [be_kind_of(String), be_kind_of(Float)]])
      end
    end

    context "when the object is a hash" do
      let(:object) do
        {
          key_1: SpecForge::Attribute.from(1),
          key_2: SpecForge::Attribute.from([
            "faker.string.random",
            "faker.number.positive"
          ])
        }
      end

      it "recursively resolves the hash" do
        expect(resolvable.resolve).to match(
          key_1: 1,
          key_2: [be_kind_of(String), be_kind_of(Float)]
        )
      end
    end

    context "when the object is an attribute" do
      let(:object) { SpecForge::Attribute.from(1) }

      it "forwards the call to the attribute" do
        expect(resolvable.resolve).to eq(1)
      end
    end

    context "when the object is anything else" do
      let(:object) { 1 }

      it "return the object" do
        expect(resolvable.resolve).to eq(1)
      end
    end
  end
end
