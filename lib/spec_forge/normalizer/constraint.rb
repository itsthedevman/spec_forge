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
          type: [Integer, String]
        },
        json: {
          type: [Hash, Array],
          default: {}
        },
        headers: {
          type: [Hash, String],
          default: {}
        }
      }.freeze

      default_label "expect"

      define_normalizer_methods(self)
    end
  end
end
