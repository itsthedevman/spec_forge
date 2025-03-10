# frozen_string_literal: true

RSpec.shared_examples("from_input_to_attribute") do
  context "when it is resolved via .from" do
    subject(:attribute) { SpecForge::Attribute.from(input) }

    it "is expected to convert to an instance of #{described_class}" do
      is_expected.to be_kind_of(described_class)
    end
  end
end
