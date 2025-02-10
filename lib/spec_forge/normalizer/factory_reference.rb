# frozen_string_literal: true

module SpecForge
  class Normalizer
    class FactoryReference < Normalizer
      STRUCTURE = {
        attributes: {
          type: Hash,
          default: {}
        },
        build_strategy: {
          type: String,
          aliases: %i[strategy],
          default: "create"
        }
      }.freeze
    end

    # On Normalizer
    class << self
      #
      # Generates an empty Attribute::Factory hash
      #
      # @return [Hash]
      #
      def default_factory_reference
        FactoryReference.default
      end

      #
      # Normalizes a Attribute::Factory hash by standardizing
      # its keys while ensuring the required data is provided or defaulted.
      # Raises InvalidStructureError if anything is missing/invalid type
      #
      # @param input [Hash] The hash to normalize
      #
      # @return [Hash] A normalized hash as a new instance
      #
      def normalize_factory_reference!(input, **)
        raise_errors! do
          normalize_factory_reference(input, **)
        end
      end

      #
      # Normalize a factory hash
      # Used internally by .normalize_factory_reference, but is available for utility
      #
      # @param factory [Hash] Attribute::Factory representation as a Hash
      #
      # @return [Array] Two item array
      #   First - The normalized hash
      #   Second - Array of errors, if any
      #
      # @private
      #
      def normalize_factory_reference(factory, label: "factory reference")
        if !Type.hash?(factory)
          raise InvalidTypeError.new(factory, Hash, for: "factory reference")
        end

        Normalizer::FactoryReference.new(label, factory).normalize
      end
    end
  end
end
