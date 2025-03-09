# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Normalizes configuration hash structure for SpecForge
    #
    # Ensures that the global configuration has the correct structure
    # and default values for all required settings.
    #
    class Configuration < Normalizer
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
        base_url: SHARED_ATTRIBUTES[:base_url].except(:default), # Make it required
        headers: SHARED_ATTRIBUTES[:headers],
        query: SHARED_ATTRIBUTES[:query],
        factories: {
          type: Hash,
          default: {},
          structure: {
            auto_discover: {
              type: [TrueClass, FalseClass],
              default: true
            },
            paths: {
              type: Array,
              default: []
            }
          }
        },
        on_debug: {
          type: Proc
        }
      }.freeze
    end

    # On Normalizer
    class << self
      #
      # Generates an empty configuration hash
      #
      # @return [Hash] Default configuration hash
      #
      def default_configuration
        Configuration.default
      end

      #
      # Normalizes a configuration hash with validation
      #
      # @param input [Hash] The hash to normalize
      #
      # @return [Hash] A normalized hash with defaults applied
      #
      # @raise [InvalidStructureError] If validation fails
      #
      def normalize_configuration!(input)
        raise_errors! do
          normalize_configuration(input)
        end
      end

      #
      # Normalize a configuration hash
      #
      # @param configuration [Hash] Configuration hash
      #
      # @return [Array] [normalized_hash, errors]
      #
      # @private
      #
      def normalize_configuration(configuration)
        if !Type.hash?(configuration)
          raise InvalidTypeError.new(configuration, Hash, for: "configuration")
        end

        Normalizer::Configuration.new("configuration", configuration).normalize
      end
    end
  end
end
