# frozen_string_literal: true

RSpec.describe SpecForge::Normalizer do
  describe ".normalize_global_context!" do
    let(:global) do
      {
        variables: {
          var_1: true,
          var_2: "faker.string.random"
        }
      }
    end

    subject(:normalized) { described_class.normalize_global_context!(global) }

    it "is expected to normalize normally" do
      expect(normalized).to include(
        variables: {
          var_1: true,
          var_2: "faker.string.random"
        }
      )
    end

    context "when 'variables' is nil" do
      before do
        global[:variables] = nil
      end

      it do
        expect(normalized[:variables]).to eq({})
      end
    end

    context "when 'variables' is not a Hash" do
      before do
        global[:variables] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected Hash, got Integer for \"variables\" in global context"
        )
      end
    end
  end
end
