# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Normalizes constraint hash structure for expectations
    #
    # Ensures that expectation constraints (status, json, etc.)
    # have the correct structure and defaults.
    #
    class Constraint < Normalizer
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
        status: {
          type: Integer
        },
        json: {
          type: [Hash, Array],
          default: {}
        }
      }.freeze
    end

    # On Normalizer
    class << self
      #
      # Generates an empty constraint hash
      #
      # @return [Hash] Default constraint hash
      #
      def default_constraint
        Constraint.default
      end

      #
      # Normalize a constraint hash
      #
      # @param constraint [Hash] Constraint hash
      #
      # @return [Array] [normalized_hash, errors]
      #
      # @private
      #
      def normalize_constraint(constraint)
        raise InvalidTypeError.new(constraint, Hash, for: "expect") unless Type.hash?(constraint)

        Normalizer::Constraint.new("expect", constraint).normalize
      end
    end
  end
end
