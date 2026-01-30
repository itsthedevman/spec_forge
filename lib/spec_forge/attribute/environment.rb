# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents an attribute that retrieves its value from an environment variable.
    # This allows specs to reference environment variables dynamically.
    #
    # @example Basic usage in YAML
    #   api_key: "{{ env.API_KEY }}"
    #   database_url: "{{ env.DATABASE_URL }}"
    #   secret: "{{ env.MY_SECRET_TOKEN }}"
    #
    class Environment < Attribute
      #
      # Regular expression pattern that matches attribute keywords with this prefix.
      # Used for identifying this attribute type during parsing.
      # Matches case-insensitively (env., ENV., Env., etc.)
      #
      # @return [Regexp]
      #
      KEYWORD_REGEX = /^env\./i

      #
      # Creates a new environment attribute by extracting the variable name
      #
      # @param input [String] The environment variable reference (e.g., "env.API_KEY")
      #
      def initialize(...)
        super

        @variable_name = input.sub(KEYWORD_REGEX, "")
      end

      #
      # Returns the value of the referenced environment variable
      #
      # @return [String, nil] The environment variable value, or nil if not set
      #
      def value
        ENV[@variable_name]
      end
    end
  end
end
