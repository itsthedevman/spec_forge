# # frozen_string_literal: true

# # This is more for organizational purposes
# RSpec.describe SpecForge::Normalizer do
#   describe ".normalize_openapi_path!" do
#     let(:input) do
#       {
#         operation_id: SecureRandom.uuid,
#         tags: ["tag_1", "tag-2"],
#         parameters: [
#           {name: "id", description: Faker::String.random, required: true},
#           {name: "name", description: Faker::String.random, required: false}
#         ],
#         security: [
#           {bearerAuth: []},
#           {oauth: []}
#         ],
#         get: {
#           tags: ["get"],
#           summary: Faker::String.random,
#           description: Faker::String.random,
#           security: [{bearerAuth: []}],
#           responses: {
#             "201": {description: Faker::String.random}
#           }
#         },
#         delete: {
#           tags: ["delete"],
#           summary: Faker::String.random,
#           description: Faker::String.random,
#           security: [{bearerAuth: []}],
#           responses: {
#             "201": {description: Faker::String.random}
#           }
#         },
#         post: {
#           tags: ["post"],
#           summary: Faker::String.random,
#           description: Faker::String.random,
#           security: [{bearerAuth: []}],
#           responses: {
#             "201": {description: Faker::String.random}
#           }
#         },
#         patch: {
#           tags: ["patch"],
#           summary: Faker::String.random,
#           description: Faker::String.random,
#           security: [{bearerAuth: []}],
#           responses: {
#             "201": {description: Faker::String.random}
#           }
#         },
#         put: {
#           tags: ["put"],
#           summary: Faker::String.random,
#           description: Faker::String.random,
#           security: [{bearerAuth: []}],
#           responses: {
#             "201": {description: Faker::String.random}
#           }
#         }
#       }
#     end

#     subject(:normalized) { described_class.normalize_openapi_path!(input) }

#     context "when everything is valid" do
#       it "is expected to return a valid hash" do
#         expect(normalized[:operation_id]).to eq(input[:operation_id])
#         expect(normalized[:tags]).to eq(input[:tags])
#         expect(normalized[:parameters]).to eq(input[:parameters])
#         expect(normalized[:security]).to eq(input[:security])
#         expect(normalized[:get]).to eq(input[:get])
#         expect(normalized[:delete]).to eq(input[:delete])
#         expect(normalized[:patch]).to eq(input[:patch])
#         expect(normalized[:post]).to eq(input[:post])
#         expect(normalized[:put]).to eq(input[:put])
#       end
#     end

#     include_examples(
#       "normalizer_defaults_value",
#       {
#         context: "when 'operation_id' is nil",
#         before: -> { input[:operation_id] = nil },
#         input: -> { normalized[:operation_id] },
#         default: nil
#       },
#       {
#         context: "when 'tags' is nil",
#         before: -> { input[:tags] = nil },
#         input: -> { normalized[:tags] },
#         default: nil
#       },
#       {
#         context: "when 'parameters' is nil",
#         before: -> { input[:parameters] = nil },
#         input: -> { normalized[:parameters] },
#         default: nil
#       },
#       {
#         context: "when 'parameters.description' is nil",
#         before: -> { input[:parameters].first[:description] = nil },
#         input: -> { normalized[:parameters].first[:description] },
#         default: nil
#       },
#       {
#         context: "when 'parameters.required' is nil",
#         before: -> { input[:parameters].first[:required] = nil },
#         input: -> { normalized[:parameters].first[:required] },
#         default: nil
#       },
#       {
#         context: "when 'security' is nil",
#         before: -> { input[:security] = nil },
#         input: -> { normalized[:security] },
#         default: nil
#       }
#     )

#     include_examples(
#       "normalizer_raises_invalid_structure",
#       {
#         context: "when 'tags' is not an array",
#         before: -> { input[:tags] = 1 },
#         error: "Expected Array, got Integer for \"tags\" in openapi paths"
#       },
#       {
#         context: "when 'tags' is not an array of strings",
#         before: -> { input[:tags] = [1] },
#         error: "Expected String, got Integer for index 0 of \"tags\" in openapi paths"
#       },
#       {
#         context: "when 'parameters' is not an array",
#         before: -> { input[:parameters] = 1 },
#         error: "Expected Array, got Integer for \"parameters\" in openapi paths"
#       },
#       {
#         context: "when 'parameters' is not an array of hashes",
#         before: -> { input[:parameters] = [1] },
#         error: "Expected Hash, got Integer for index 0 of \"parameters\" in openapi paths"
#       },
#       {
#         context: "when 'parameters.name' is nil",
#         before: -> { input[:parameters].first[:name] = nil },
#         error: "Expected String, got NilClass for \"name\" in index 0 of \"parameters\" in openapi paths"
#       },
#       {
#         context: "when 'parameters.name' is not a string",
#         before: -> { input[:parameters].first[:name] = 1 },
#         error: "Expected String, got Integer for \"name\" in index 0 of \"parameters\" in openapi paths"
#       },
#       {
#         context: "when 'parameters.description' is not a string",
#         before: -> { input[:parameters].first[:description] = 1 },
#         error: "Expected String, got Integer for \"description\" in index 0 of \"parameters\" in openapi paths"
#       },
#       {
#         context: "when 'parameters.required' is not true/false",
#         before: -> { input[:parameters].first[:required] = 1 },
#         error: "Expected TrueClass or FalseClass, got Integer for \"required\" in index 0 of \"parameters\" in openapi paths"
#       },
#       {
#         context: "when 'security' is not an array",
#         before: -> { input[:security] = 1 },
#         error: "Expected Array, got Integer for \"security\" in openapi paths"
#       },
#       {
#         context: "when 'security' is not an array of hashes",
#         before: -> { input[:security] = [1] },
#         error: "Expected Hash, got Integer for index 0 of \"security\" in openapi paths"
#       }
#     )

#     %i[get delete post patch put].each do |verb|
#       include_examples(
#         "normalizer_defaults_value",
#         {
#           context: "when '#{verb}' is nil",
#           before: -> { input[verb] = nil },
#           input: -> { normalized[verb] },
#           default: nil
#         },
#         {
#           context: "when '#{verb}.tags' is nil",
#           before: -> { input[verb][:tags] = nil },
#           input: -> { normalized[verb][:tags] },
#           default: nil
#         },
#         {
#           context: "when '#{verb}.security' is nil",
#           before: -> { input[verb][:security] = nil },
#           input: -> { normalized[verb][:security] },
#           default: nil
#         },
#         {
#           context: "when '#{verb}.parameters' is nil",
#           before: -> { input[verb][:parameters] = nil },
#           input: -> { normalized[verb][:parameters] },
#           default: nil
#         },
#         {
#           context: "when '#{verb}.summary' is nil",
#           before: -> { input[verb][:summary] = nil },
#           input: -> { normalized[verb][:summary] },
#           default: nil
#         },
#         {
#           context: "when '#{verb}.description' is nil",
#           before: -> { input[verb][:description] = nil },
#           input: -> { normalized[verb][:description] },
#           default: nil
#         },
#         {
#           context: "when '#{verb}.responses' is nil",
#           before: -> { input[verb][:responses] = nil },
#           input: -> { normalized[verb][:responses] },
#           default: nil
#         }
#       )

#       include_examples(
#         "normalizer_raises_invalid_structure",
#         {
#           context: "when '#{verb}' is not a hash",
#           before: -> { input[verb] = 1 },
#           error: "Expected Hash, got Integer for \"#{verb}\" in openapi paths"
#         },
#         {
#           context: "when '#{verb}.tags' is not an array",
#           before: -> { input[verb][:tags] = 1 },
#           error: "Expected Array, got Integer for \"tags\" in \"#{verb}\" in openapi paths"
#         },
#         {
#           context: "when '#{verb}.security' is not an array",
#           before: -> { input[verb][:security] = 1 },
#           error: "Expected Array, got Integer for \"security\" in \"#{verb}\" in openapi paths"
#         },
#         {
#           context: "when '#{verb}.parameters' is not an array",
#           before: -> { input[verb][:parameters] = 1 },
#           error: "Expected Array, got Integer for \"parameters\" in \"#{verb}\" in openapi paths"
#         },
#         {
#           context: "when '#{verb}.summary' is not a string",
#           before: -> { input[verb][:summary] = 1 },
#           error: "Expected String, got Integer for \"summary\" in \"#{verb}\" in openapi paths"
#         },
#         {
#           context: "when '#{verb}.description' is not a string",
#           before: -> { input[verb][:description] = 1 },
#           error: "Expected String, got Integer for \"description\" in \"#{verb}\" in openapi paths"
#         },
#         {
#           context: "when '#{verb}.responses' is not a hash",
#           before: -> { input[verb][:responses] = 1 },
#           error: "Expected Hash, got Integer for \"responses\" in \"#{verb}\" in openapi paths"
#         },
#         {
#           context: "when a status code in '#{verb}.responses' is not a hash",
#           before: -> { input[verb][:responses]["201"] = 1 },
#           error: "Expected Hash, got Integer for \"201\" in \"#{verb}\" in openapi paths"
#         },
#         {
#           context: "when a status code in '#{verb}.responses.description' is nil",
#           before: lambda do
#             input[verb][:responses]["201"] = {description: nil}
#           end,
#           error: "Expected String, got NilClass for \"description\" in \"201\" in \"#{verb}\" in openapi paths"
#         },
#         {
#           context: "when a status code in '#{verb}.responses.description' is not a string",
#           before: lambda do
#             input[verb][:responses]["201"] = {description: 1}
#           end,
#           error: "Expected String, got Integer for \"description\" in \"201\" in \"#{verb}\" in openapi paths"
#         }
#       )
#     end
#   end
# end
