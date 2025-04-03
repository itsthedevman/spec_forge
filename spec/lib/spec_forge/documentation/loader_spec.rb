# frozen_string_literal: true

RSpec.describe SpecForge::Documentation::Loader do
  describe ".load" do
    let(:forges) { [] }

    subject(:loaded) { described_class.load(forges) }

    context "when there are no forges" do
      let(:forges) { [] }

      it "is expected to return an empty array" do
        is_expected.to eq([])
      end
    end

    context "when there are forges" do
      let(:forges) do
        []
      end

      it "is expected to normalize the data" do
        is_expected.to eq({})
      end
    end
  end
end
