# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Normalizes documentation configuration hash structure for SpecForge
    #
    # Ensures that the configuration has the correct structure
    # and default values for all required settings.
    #
    class DocumentationConfig < Normalizer
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
        openapi: {
          type: Hash,
          default: {},
          structure: {
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
          }
        }
      }.freeze
    end

    # On Normalizer
    class << self
      #
      # Generates an empty documentation configuration hash
      #
      # @return [Hash] Default configuration hash
      #
      def default_documentation_config
        DocumentationConfig.default
      end

      #
      # Normalizes a documentation configuration hash with validation
      #
      # @param input [Hash] The hash to normalize
      #
      # @return [Hash] A normalized hash with defaults applied
      #
      # @raise [Error::InvalidStructureError] If validation fails
      #
      def normalize_documentation_config!(input)
        raise_errors! do
          normalize_documentation_config(input)
        end
      end

      #
      # Normalize a documentation configuration hash
      #
      # @param configuration [Hash] Configuration hash
      #
      # @return [Array] [normalized_hash, errors]
      #
      # @private
      #
      def normalize_documentation_config(configuration)
        if !Type.hash?(configuration)
          raise Error::InvalidTypeError.new(configuration, Hash, for: "documentation config")
        end

        Normalizer::DocumentationConfig.new("documentation config", configuration).normalize
      end
    end
  end
end
