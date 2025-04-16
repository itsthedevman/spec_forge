# frozen_string_literal: true

# This is more for organizational purposes
RSpec.describe SpecForge::Normalizer do
  describe ".normalize_openapi_path!" do
    let(:input) do
      {
        tags: ["tag_1", "tag-2"],
        parameters: [
          {name: "id", description: Faker::String.random, required: true},
          {name: "name", description: Faker::String.random, required: false}
        ],
        security: [
          {bearerAuth: []},
          {oauth: []}
        ],
        get: {
          tags: ["get"],
          summary: Faker::String.random,
          description: Faker::String.random,
          security: [{bearerAuth: []}],
          responses: {} # Normalized with openapi_response
        },
        delete: {
          tags: ["delete"],
          summary: Faker::String.random,
          description: Faker::String.random,
          security: [{bearerAuth: []}],
          responses: {} # Normalized with openapi_response
        },
        post: {
          tags: ["post"],
          summary: Faker::String.random,
          description: Faker::String.random,
          security: [{bearerAuth: []}],
          responses: {} # Normalized with openapi_response
        },
        patch: {
          tags: ["patch"],
          summary: Faker::String.random,
          description: Faker::String.random,
          security: [{bearerAuth: []}],
          responses: {} # Normalized with openapi_response
        },
        put: {
          tags: ["put"],
          summary: Faker::String.random,
          description: Faker::String.random,
          security: [{bearerAuth: []}],
          responses: {} # Normalized with openapi_response
        }
      }
    end

    subject(:normalized) { described_class.normalize_openapi_path!(input) }

    context "when everything is valid"

    include_examples(
      "normalizer_defaults_value",
      {
        context: "when 'tags' is nil",
        before: -> { input[:tags] = nil },
        input: -> { normalized[:tags] },
        default: []
      },
      {
        context: "when 'parameters' is nil",
        before: -> { input[:parameters] = nil },
        input: -> { normalized[:parameters] },
        default: []
      },
      {
        context: "when 'parameters.description' is nil",
        before: -> { input[:parameters].first[:description] = nil },
        input: -> { normalized[:parameters].first[:description] },
        default: nil
      },
      {
        context: "when 'parameters.required' is nil",
        before: -> { input[:parameters].first[:required] = nil },
        input: -> { normalized[:parameters].first[:required] },
        default: nil
      },
      {
        context: "when 'security' is nil",
        before: -> { input[:security] = nil },
        input: -> { normalized[:security] },
        default: []
      }
    )

    include_examples(
      "normalizer_raises_invalid_structure",
      {
        context: "when 'tags' is not an array",
        before: -> { input[:tags] = 1 },
        error: "Expected Array, got Integer for \"tags\" in openapi paths"
      },
      {
        context: "when 'tags' is not an array of strings",
        before: -> { input[:tags] = [1] },
        error: "Expected String, got Integer for index 0 of \"tags\" in openapi paths"
      },
      {
        context: "when 'parameters' is not an array",
        before: -> { input[:parameters] = 1 },
        error: "Expected Array, got Integer for \"parameters\" in openapi paths"
      },
      {
        context: "when 'parameters' is not an array of hashes",
        before: -> { input[:parameters] = [1] },
        error: "Expected Hash, got Integer for index 0 of \"parameters\" in openapi paths"
      },
      {
        context: "when 'parameters.name' is nil",
        before: -> { input[:parameters].first[:name] = nil },
        error: "Expected String, got NilClass for \"name\" in index 0 of \"parameters\" in openapi paths"
      },
      {
        context: "when 'parameters.name' is not a string",
        before: -> { input[:parameters].first[:name] = 1 },
        error: "Expected String, got Integer for \"name\" in index 0 of \"parameters\" in openapi paths"
      },
      {
        context: "when 'parameters.description' is not a string",
        before: -> { input[:parameters].first[:description] = 1 },
        error: "Expected String, got Integer for \"description\" in index 0 of \"parameters\" in openapi paths"
      },
      {
        context: "when 'parameters.required' is not true/false",
        before: -> { input[:parameters].first[:required] = 1 },
        error: "Expected TrueClass or FalseClass, got Integer for \"required\" in index 0 of \"parameters\" in openapi paths"
      },
      {
        context: "when 'security' is not an array",
        before: -> { input[:security] = 1 },
        error: "Expected Array, got Integer for \"security\" in openapi paths"
      },
      {
        context: "when 'security' is not an array of hashes",
        before: -> { input[:security] = [1] },
        error: "Expected Hash, got Integer for index 0 of \"security\" in openapi paths"
      }
    )

    # %w[get delete post patch put].each do |verb|
    #   # Defaults
    #   "when '#{verb}' is nil"
    #   "when '#{verb}.tags' is nil"
    #   "when '#{verb}.security' is nil"
    #   "when '#{verb}.parameters' is nil"
    #   "when '#{verb}.summary' is nil"
    #   "when '#{verb}.description' is nil"
    #   "when '#{verb}.description' is nil"

    #   # Raises
    #   "when '#{verb}' is not a hash"
    #   "when '#{verb}.tags' is not an array"
    #   "when '#{verb}.security' is not an array"
    #   "when '#{verb}.parameters' is not an array"
    #   "when '#{verb}.summary' is not a string"
    #   "when '#{verb}.description' is not a string"
    #   "when '#{verb}.description' is not a hash"
    # end
  end
end
