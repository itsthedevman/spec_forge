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
            required: {type: [TrueClass, FalseClass], default: nil}
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
          tags:,
          security:,
          parameters:,
          summary: {type: String, default: nil},
          description: {type: String, default: nil},
          responses: {type: Hash, default: nil}
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
