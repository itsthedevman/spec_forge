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
          security: {bearerAuth: []},
          responses: {} # Normalized with openapi_response
        },
        delete: {
          tags: ["delete"],
          summary: Faker::String.random,
          description: Faker::String.random,
          security: {bearerAuth: []},
          responses: {} # Normalized with openapi_response
        },
        post: {
          tags: ["post"],
          summary: Faker::String.random,
          description: Faker::String.random,
          security: {bearerAuth: []},
          responses: {} # Normalized with openapi_response
        },
        patch: {
          tags: ["patch"],
          summary: Faker::String.random,
          description: Faker::String.random,
          security: {bearerAuth: []},
          responses: {} # Normalized with openapi_response
        },
        put: {
          tags: ["put"],
          summary: Faker::String.random,
          description: Faker::String.random,
          security: {bearerAuth: []},
          responses: {} # Normalized with openapi_response
        }
      }
    end

    subject(:normalized) { described_class.normalize_openapi_path!(input) }

    context "when everything is valid"

    context "when tags is nil"
    context "when tags is not an array"
    context "when tags is not an array of strings"

    context "when parameters is not "

  end
end
