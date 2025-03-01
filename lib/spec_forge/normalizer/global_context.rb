# frozen_string_literal: true

module SpecForge
  class Normalizer
    class GlobalContext < Normalizer
      STRUCTURE = {
        variables: Normalizer::SHARED_ATTRIBUTES[:variables]
      }.freeze
    end

    # On Normalizer
    class << self
      #
      # Generates an empty global context hash
      #
      # @return [Hash]
      #
      def default_global_context
        GlobalContext.default
      end

      #
      # Normalizes a global context hash by standardizing its keys while ensuring the required data
      # is provided or defaulted.
      # Raises InvalidStructureError if anything is missing/invalid type
      #
      # @param input [Hash] The hash to normalize
      #
      # @return [Hash] A normalized hash as a new instance
      #
      def normalize_global_context!(input)
        raise_errors! do
          normalize_global_context(input)
        end
      end

      #
      # Normalize a global context hash
      # Used internally by .normalize_global_context!, but is available for utility
      #
      # @param global [Hash] Global context representation as a Hash
      #
      # @return [Array] Two item array
      #   First - The normalized hash
      #   Second - Array of errors, if any
      #
      # @private
      #
      def normalize_global_context(global)
        if !Type.hash?(global)
          raise InvalidTypeError.new(global, Hash, for: "global context")
        end

        Normalizer::GlobalContext.new("global context", global).normalize
      end
    end
  end
end
