# frozen_string_literal: true

RSpec.describe SpecForge::Normalizer do
  describe ".normalize_global_context!" do
    let(:global) do
      {
        variables: {
          var_1: true,
          var_2: "faker.string.random"
        },
        callbacks: [
          {before: "test_callback"}
        ]
      }
    end

    subject(:normalized) { described_class.normalize_global_context!(global) }

    before do
      SpecForge::Callbacks.register("test_callback") {}
    end

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
          SpecForge::Error::InvalidStructureError,
          "Expected Hash or String, got Integer for \"variables\" in global context"
        )
      end
    end

    context "when 'callbacks' is nil" do
      before do
        global[:callbacks] = nil
      end

      it "is expected to default it to an empty hash" do
        expect(normalized[:callbacks]).to eq([])
      end
    end

    context "when 'callbacks' is not a Array" do
      before do
        global[:callbacks] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected Array, got Integer for \"callbacks\" in global context"
        )
      end
    end

    context "when 'callbacks' is not an array of objects" do
      before do
        global[:callbacks] = ["test_callback"]
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          "Expected Hash, got String for index 0 of \"callbacks\" in global context"
        )
      end
    end

    context "when a callback name is not a String" do
      before do
        global[:callbacks] = [
          {before: 1}
        ]
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          %{Expected String or NilClass, got Integer for "before_each" (aliases "before") in index 0 of "callbacks" in global context}
        )
      end
    end

    context "when a callback name is not defined" do
      before do
        global[:callbacks] = [
          {before: "Not defined, yo"}
        ]
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::Error::InvalidStructureError,
          %(The callback "Not defined, yo" was referenced but hasn't been defined.\nAvailable callbacks are: "test_callback")
        )
      end
    end
  end
end
