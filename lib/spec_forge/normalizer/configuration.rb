# frozen_string_literal: true

module SpecForge
  class Normalizer
    class Configuration < Normalizer
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
      # @return [Hash]
      #
      def default_configuration
        Configuration.default
      end

      #
      # Normalizes a configuration hash by standardizing its keys while ensuring the required data
      # is provided or defaulted.
      # Raises InvalidStructureError if anything is missing/invalid type
      #
      # @param input [Hash] The hash to normalize
      #
      # @return [Hash] A normalized hash as a new instance
      #
      def normalize_configuration!(input)
        raise_errors! do
          normalize_configuration(input)
        end
      end

      #
      # Normalize a configuration hash
      # Used internally by .normalize_configuration!, but is available for utility
      #
      # @param configuration [Hash] Configuration representation as a Hash
      #
      # @return [Array] Two item array
      #   First - The normalized hash
      #   Second - Array of errors, if any
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
