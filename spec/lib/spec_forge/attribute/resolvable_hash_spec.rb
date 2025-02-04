# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::ResolvableHash do
  let(:object) {}

  subject(:resolvable) { described_class.new(object) }

  describe "#resolve" do
    let(:object) do
      {
        key_1: SpecForge::Attribute.from(1),
        key_2: SpecForge::Attribute.from({
          key_3: SpecForge::Attribute.from([
            "faker.string.random"
          ])
        })
      }
    end

    it { expect(resolvable).to respond_to(:resolve) }

    it "recursively resolves the hash" do
      resolved = resolvable.resolve
      expect(resolved[:key_1]).to eq(1)
      expect(resolved[:key_2]).to be_kind_of(Hash)
      expect(resolved[:key_2][:key_3].first).to be_kind_of(String)
    end
  end
end
