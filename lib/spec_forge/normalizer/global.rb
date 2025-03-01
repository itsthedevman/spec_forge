# frozen_string_literal: true

module SpecForge
  class Normalizer
    class Global < Normalizer
      STRUCTURE = {
        variables: Normalizer::SHARED_ATTRIBUTES[:variables]
      }.freeze
    end

    # On Normalizer
    class << self
      #
      # Generates an empty global hash
      #
      # @return [Hash]
      #
      def default_global
        Global.default
      end

      #
      # Normalizes a global hash by standardizing its keys while ensuring the required data
      # is provided or defaulted.
      # Raises InvalidStructureError if anything is missing/invalid type
      #
      # @param input [Hash] The hash to normalize
      #
      # @return [Hash] A normalized hash as a new instance
      #
      def normalize_global!(input)
        raise_errors! do
          normalize_global(input)
        end
      end

      #
      # Normalize a global hash
      # Used internally by .normalize_global!, but is available for utility
      #
      # @param global [Hash] Global context representation as a Hash
      #
      # @return [Array] Two item array
      #   First - The normalized hash
      #   Second - Array of errors, if any
      #
      # @private
      #
      def normalize_global(global)
        if !Type.hash?(global)
          raise InvalidTypeError.new(global, Hash, for: "global")
        end

        Normalizer::Global.new("global", global).normalize
      end
    end
  end
end
