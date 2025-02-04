# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::ResolvableArray do
  let(:object) {}

  subject(:resolvable) { described_class.new(object) }

  describe "#resolve" do
    let(:object) do
      [
        SpecForge::Attribute.from(1),
        SpecForge::Attribute.from([
          SpecForge::Attribute.from([
            "faker.string.random",
            "faker.number.positive"
          ])
        ])
      ]
    end

    it { expect(resolvable).to respond_to(:resolve) }

    it "recursively resolves the array" do
      resolved = resolvable.resolve
      expect(resolved.first).to eq(1)
      expect(resolved.second).to be_kind_of(Array)

      inner_array = resolved.second.first
      expect(inner_array).to be_kind_of(Array)
      expect(inner_array.first).to be_kind_of(String)
      expect(inner_array.second).to be_kind_of(Numeric)
    end
  end
end
