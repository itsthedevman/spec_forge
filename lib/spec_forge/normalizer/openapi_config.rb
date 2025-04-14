# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Normalizes OpenAPI configuration hash structure for SpecForge
    #
    # Ensures that the configuration has the correct structure
    # and default values for all required settings.
    #
    class OpenapiConfig < Normalizer
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
        info: {
          type: Hash,
          default: {},
          structure: {
            title: {type: String},
            version: {type: String},
            description: {type: String, default: ""},
            contact: {
              type: Hash,
              default: {},
              structure: {
                name: {type: String, default: ""},
                email: {type: String, default: ""}
              }
            },
            license: {
              type: Hash,
              default: {},
              structure: {
                name: {type: String, default: ""},
                url: {type: String, default: ""}
              }
            }
          }
        },
        servers: {
          type: Array,
          default: [],
          structure: {
            type: Hash,
            structure: {
              url: {type: String, default: ""},
              description: {type: String, default: ""}
            }
          }
        },
        tags: {
          type: Hash,
          default: {}
        },
        security_schemes: {
          type: Hash,
          default: {}
        }
      }.freeze

      default_label "openapi/config/openapi.yml"

      define_normalizer_methods(self)
    end
  end
end
