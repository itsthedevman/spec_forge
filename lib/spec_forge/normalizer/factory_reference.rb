# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Normalizes factory reference hash structure
    #
    # Ensures that factory references have the correct structure
    # and default values for all required settings.
    #
    class FactoryReference < Normalizer
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
        attributes: {
          type: Hash,
          default: {}
        },
        build_strategy: {
          type: String,
          aliases: %i[strategy],
          default: "create"
        },
        size: {
          type: Integer,
          aliases: %i[count],
          default: 0
        }
      }.freeze
    end

    # On Normalizer
    class << self
      #
      # Generates an empty factory reference hash
      #
      # @return [Hash] Default factory reference hash
      #
      def default_factory_reference
        FactoryReference.default
      end

      #
      # Normalizes a factory reference hash with validation
      #
      # @param input [Hash] The hash to normalize
      #
      # @return [Hash] A normalized hash with defaults applied
      #
      # @raise [Error::InvalidStructureError] If validation fails
      #
      def normalize_factory_reference!(input, **)
        raise_errors! do
          normalize_factory_reference(input, **)
        end
      end

      #
      # Normalize a factory reference hash
      #
      # @param factory [Hash] Factory reference hash
      # @param label [String] Label for error messages
      #
      # @return [Array] [normalized_hash, errors]
      #
      # @private
      #
      def normalize_factory_reference(factory, label: "factory reference")
        if !Type.hash?(factory)
          raise Error::InvalidTypeError.new(factory, Hash, for: "factory reference")
        end

        Normalizer::FactoryReference.new(label, factory).normalize
      end
    end
  end
end
