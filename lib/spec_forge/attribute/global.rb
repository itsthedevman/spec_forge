# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents an attribute that references values from the global context
    #
    # This class allows accessing shared data defined at the global level through
    # namespaced references. It provides access to global variables that are shared
    # across all specs in a file, enabling consistent test data without repetition.
    #
    # Currently supports the "variables" namespace.
    #
    # @example Basic usage in YAML
    #   # Reference a global variable in a spec
    #   session_token: global.variables.session_token
    #
    #   # Using within a request body
    #   body:
    #     api_version: global.variables.api_version
    #     auth_token: global.variables.auth_token
    #
    class Global < Attribute
      #
      # Regular expression pattern that matches attribute keywords with this prefix
      # Used for identifying this attribute type during parsing
      #
      # @return [Regexp]
      #
      KEYWORD_REGEX = /^global\./i

      #
      # An array of valid namespaces that can be access on global
      #
      # @return [Array<String>]
      #
      VALID_NAMESPACES = %w[
        variables
      ].freeze

      #
      # Creates a new global attribute from the input string
      #
      # Parses the input string to extract the namespace to validate it
      # Conversion happens when `#value` is called
      #
      # @raise [Error::InvalidGlobalNamespaceError] If an unsupported namespace is referenced
      #
      def initialize(...)
        super

        # Check to make sure the namespace is valid
        namespace = input.split(".").second

        if !VALID_NAMESPACES.include?(namespace)
          raise Error::InvalidGlobalNamespaceError, namespace
        end
      end

      #
      # Converts the global reference into an underlying attribute
      #
      # Parses the input and returns the corresponding attribute based on the namespace.
      # Currently supports extracting variables from the global context.
      #
      # @return [Attribute] An attribute representing the referenced global value
      #
      def value
        # Skip the "global" prefix
        components = input.split(".")[1..]
        namespace = components.first

        global_context = SpecForge.context.global

        case namespace
        when "variables"
          variable_input = components.join(".")
          variable = Attribute::Variable.new(variable_input)
          variable.bind_variables(global_context.variables.to_h)
          variable
        end
      end

      #
      # Resolves the global reference to its actual value
      #
      # Delegates resolution to the underlying attribute and caches the result
      #
      # @return [Object] The fully resolved value from the global context
      #
      def resolved
        @resolved ||= value.resolved
      end
    end
  end
end
