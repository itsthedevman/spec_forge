# frozen_string_literal: true

module SpecForge
  class Normalizer
    class Constraint < Normalizer
      STRUCTURE = {
        status: {
          type: Integer
        },
        json: {
          type: Hash,
          default: {}
        }
      }.freeze
    end

    # On Normalizer
    class << self
      #
      # Generates an empty constraint hash
      #
      # @return [Hash]
      #
      def default_constraint
        Constraint.default
      end

      #
      # Normalize a constraint hash
      # Used internally by .normalize_spec, but is available for utility
      #
      # @param constraint [Hash] Constraint representation as a Hash
      #
      # @return [Array] Two item array
      #   First - The normalized hash
      #   Second - Array of errors, if any
      #
      # @private
      #
      def normalize_constraint(constraint)
        raise InvalidTypeError.new(constraint, Hash, for: "expect") if !constraint.is_a?(Hash)

        Normalizer::Constraint.new("expect", constraint).normalize
      end
    end
  end
end
