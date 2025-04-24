# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Normalizes global context hash structure
    #
    # Ensures that global context definitions have the correct structure
    # and default values for all required settings.
    #
    class GlobalContext < Normalizer
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
        variables: Normalizer::SHARED_ATTRIBUTES[:variables],
        callbacks: {
          type: Array,
          default: [],
          structure: {
            type: Hash,
            default: {},
            structure: {
              before_file: Normalizer::SHARED_ATTRIBUTES[:callback],
              before_spec: Normalizer::SHARED_ATTRIBUTES[:callback],
              before_each: Normalizer::SHARED_ATTRIBUTES[:callback].merge(aliases: %i[before]),
              around_each: Normalizer::SHARED_ATTRIBUTES[:callback].merge(aliases: %i[around]),
              after_each: Normalizer::SHARED_ATTRIBUTES[:callback].merge(aliases: %i[after]),
              after_spec: Normalizer::SHARED_ATTRIBUTES[:callback],
              after_file: Normalizer::SHARED_ATTRIBUTES[:callback]
            }
          }
        }
      }.freeze

      define_normalizer_methods(self)
    end
  end
end
