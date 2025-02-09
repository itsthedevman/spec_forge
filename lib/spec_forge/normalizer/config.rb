# frozen_string_literal: true

module SpecForge
  class Normalizer
    class Config < Normalizer
      STRUCTURE = {
        environment: {
          # Allows for a shorthand:
          #   environment: rails
          # Long form:
          #   environment:
          #     use: rails
          type: [String, Hash],
          default: "rails",
          structure: {
            use: {type: String, default: "rails"},
            preload: {type: String, default: ""},
            models_path: {
              type: String,
              aliases: %i[models],
              default: ""
            }
          }
        },
        base_url: {type: String}, # Required
        authorization: {
          type: Hash,
          default: {
            # Default is a key on this hash
            default: {}
          },
          structure: {
            default: {
              type: Hash,
              structure: {
                header: {type: String, default: ""},
                value: {type: String, default: ""}
              }
            }
          }
        },
        factories: {
          type: Hash,
          default: {},
          structure: {
            paths: {
              type: Array,
              default: []
            },
            auto_discover: {
              type: [TrueClass, FalseClass],
              default: true
            }
          }
        }
      }.freeze
    end

    # On Normalizer
    class << self
      #
      # Generates an empty config hash
      #
      # @return [Hash]
      #
      def default_config
        Config.default
      end

      #
      # Normalizes a config hash by standardizing its keys while ensuring the required data
      # is provided or defaulted.
      # Raises InvalidStructureError if anything is missing/invalid type
      #
      # @param input [Hash] The hash to normalize
      #
      # @return [Hash] A normalized hash as a new instance
      #
      def normalize_config!(input)
        raise_errors! do
          normalize_config(input)
        end
      end

      #
      # Normalize a config hash
      # Used internally by .normalize_config, but is available for utility
      #
      # @param config [Hash] Config representation as a Hash
      #
      # @return [Array] Two item array
      #   First - The normalized hash
      #   Second - Array of errors, if any
      #
      # @private
      #
      def normalize_config(config)
        raise InvalidTypeError.new(config, Hash, for: "config") if !config.is_a?(Hash)

        Normalizer::Config.new("config", config).normalize
      end
    end
  end
end
