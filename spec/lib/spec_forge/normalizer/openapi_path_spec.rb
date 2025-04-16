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

    # Defaults

    # Raises
    # "when 'tags' is not an array"
    # "when 'tags' is not an array of strings"
    # "when 'parameters' is not an array"
    # "when 'parameters' is not an array of hashes"
    # "when 'parameters.name' is nil"
    # "when 'parameters.name' is not a string"
    # "when 'parameters.description' is not a string"
    # "when 'parameters.required' is not true/false"
    # "when 'security' is not an array"
    # "when 'security' is not an array of hashes"

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

    # include_examples(
    #   "normalizer_defaults_value",
    #   {
    #     context: xxx,
    #     before: -> xxx,
    #     input: -> { xxx },
    #     default: xxx
    #   },
    # )

    # include_examples(
    #   "normalizer_raises_invalid_structure",
    #   {
    #     context: xxx,
    #     before: -> xxx,
    #     error: xxx
    #   },
    # )
  end
end
