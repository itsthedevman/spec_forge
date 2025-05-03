# frozen_string_literal: true

RSpec.describe SpecForge::Normalizer do
  describe "normalize using global_context" do
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

    subject(:normalized) { described_class.normalize!(global, using: :global_context) }

    before do
      SpecForge::Callbacks.register("test_callback") {}
    end

    it "is expected to normalize normally" do
      expect(normalized).to match(
        callbacks: [{before_each: "test_callback"}],
        variables: {
          var_1: true,
          var_2: "faker.string.random"
        }
      )
    end

    include_examples(
      "normalizer_defaults_value",
      {
        context: "when 'variables' is nil",
        before: -> { global[:variables] = nil },
        input: -> { normalized[:variables] },
        default: {}
      },
      {
        context: "when 'callbacks' is nil",
        before: -> { global[:callbacks] = nil },
        input: -> { normalized[:callbacks] },
        default: []
      }
    )

    include_examples(
      "normalizer_raises_invalid_structure",
      {
        context: "when 'variables' is not a Hash",
        before: -> { global[:variables] = 1 },
        error: "Expected Hash or String, got Integer for \"variables\" in global context"
      },
      {
        context: "when 'callbacks' is not a Array",
        before: -> { global[:callbacks] = 1 },
        error: "Expected Array, got Integer for \"callbacks\" in global context"
      },
      {
        context: "when 'callbacks' is not an array of objects",
        before: -> { global[:callbacks] = ["test_callback"] },
        error: "Expected Hash, got String for index 0 of \"callbacks\" in global context"
      },
      {
        context: "when a callback name is not a String",
        before: -> { global[:callbacks] = [{before: 1}] },
        error: %{Expected String, got Integer for "before_each" (aliases "before") in index 0 of "callbacks" in global context}
      },
      {
        context: "when a callback name is not defined",
        before: -> { global[:callbacks] = [{before: "Not defined, yo"}] },
        error: %(The callback "Not defined, yo" was referenced but hasn't been defined.\nAvailable callbacks are: "test_callback")
      }
    )
  end
end
