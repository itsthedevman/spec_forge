# frozen_string_literal: true

RSpec.describe SpecForge::Normalizer do
  describe ".normalize_openapi_response!" do
    let(:input) do
      {
        description: Faker::String.random
      }
    end

    subject(:normalized) { described_class.normalize_openapi_response!(input) }

    context "when the input is valid" do
      it "is expected to pass normalization" do
        is_expected.to match(input)
      end
    end

    include_examples(
      "normalizer_raises_invalid_structure",
      {
        context: "when 'description' is nil",
        before: -> { input[:description] = nil },
        error: "Expected String, got NilClass for \"description\" in openapi paths response"
      },
      {
        context: "when 'description' is not a string",
        before: -> { input[:description] = 1 },
        error: "Expected String, got Integer for \"description\" in openapi paths response"
      }
    )
  end
end
