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
      before { global[:variables] = nil }

      it do
        expect(normalized[:variables]).to eq({})
      end
    end

    context "when 'variables' is not a Hash" do
      before { global[:variables] = 1 }

      include_examples("raises_invalid_structure_error") do
        let(:error_message) do
          "Expected Hash or String, got Integer for \"variables\" in global context"
        end
      end
    end

    context "when 'callbacks' is nil" do
      before { global[:callbacks] = nil }

      it "is expected to default it to an empty hash" do
        expect(normalized[:callbacks]).to eq([])
      end
    end

    context "when 'callbacks' is not a Array" do
      before { global[:callbacks] = 1 }

      include_examples("raises_invalid_structure_error") do
        let(:error_message) do
          "Expected Array, got Integer for \"callbacks\" in global context"
        end
      end
    end

    context "when 'callbacks' is not an array of objects" do
      before { global[:callbacks] = ["test_callback"] }

      include_examples("raises_invalid_structure_error") do
        let(:error_message) do
          "Expected Hash, got String for index 0 of \"callbacks\" in global context"
        end
      end
    end

    context "when a callback name is not a String" do
      before { global[:callbacks] = [{before: 1}] }

      include_examples("raises_invalid_structure_error") do
        let(:error_message) do
          %{Expected String or NilClass, got Integer for "before_each" (aliases "before") in index 0 of "callbacks" in global context}
        end
      end
    end

    context "when a callback name is not defined" do
      before { global[:callbacks] = [{before: "Not defined, yo"}] }

      include_examples("raises_invalid_structure_error") do
        let(:error_message) do
          %(The callback "Not defined, yo" was referenced but hasn't been defined.\nAvailable callbacks are: "test_callback")
        end
      end
    end
  end
end
