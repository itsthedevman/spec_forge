# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Normalizes OpenAPI path hash structure for SpecForge
    #
    # Ensures that the path has the correct structure
    # and default values for all required settings.
    #
    class OpenapiPath < Normalizer
      parameters = {
        type: Array,
        default: nil,
        structure: {
          type: Hash,
          structure: {
            name: {type: String},
            description: {type: String, default: nil},
            required: {type: TYPES[:boolean], default: nil}
          }
        }
      }

      security = {
        type: Array,
        default: nil,
        structure: {type: Hash}
      }

      tags = {
        type: Array,
        default: nil,
        structure: {type: String}
      }

      operation = {
        type: Hash,
        default: nil,
        structure: {
          operation_id: {type: String, default: nil},
          tags:,
          summary: {type: String, default: nil},
          description: {type: String, default: nil},
          request_body: {
            type: Hash,
            default: nil,
            structure: {
              description: {},
              content: {},
              required: {
                type: TYPES[:boolean]
              }
            }
          },
          security:,
          parameters:,
          responses: {
            type: Hash,
            default: nil,
            structure: lambda do |output, errors:, label:|
              return output if output.blank?

              output.transform_values.with_key do |hash, status_code|
                new_label = "#{status_code.in_quotes} in #{label}"
                hash, new_errors = Normalizer::OpenapiResponse.normalize(hash, label: new_label)

                errors.merge(new_errors) if new_errors.size > 0
                hash
              end
            end
          }
        }
      }

      #
      # Defines the normalized structure for configuration validation
      #
      # Specifies validation rules for configuration attributes:
      # - Enforces specific data types
      # - Provides default values
      # - Supports alternative key names
      #
      # @return [Hash] Configuration attribute validation rules
      #
      STRUCTURE = {
        tags:,
        parameters:,
        security:,
        get: operation,
        delete: operation,
        post: operation,
        patch: operation,
        put: operation
      }.freeze

      default_label "openapi paths"

      define_normalizer_methods(self)
    end
  end
end
