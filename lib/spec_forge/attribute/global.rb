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
      # The underlying attribute that will be resolved
      # For variables, this will be a Variable attribute instance
      #
      # @return [Attribute] The wrapped attribute instance
      #
      attr_reader :value

      #
      # Creates a new global attribute from the input string
      #
      # Parses the input string to extract the namespace and path,
      # then creates the appropriate attribute type to handle the resolution.
      #
      # @raise [InvalidGlobalNamespaceError] If an unsupported namespace is referenced
      #
      def initialize(...)
        super

        # Skip the "global" prefix
        components = input.split(".")[1..]
        namespace = components.first

        global_context = SpecForge.context.global

        @value =
          case namespace
          when "variables"
            variable_input = components.join(".")
            variable = Attribute::Variable.new(variable_input)
            variable.bind_variables(global_context.variables.to_h)
            variable
          else
            raise InvalidGlobalNamespaceError, namespace
          end
      end

      #
      # Resolves the global reference to its actual value
      #
      # Delegates resolution to the underlying attribute and caches the result
      #
      # @return [Object] The fully resolved value from the global context
      #
      def resolve
        @resolved ||= @value.resolve
      end
    end
  end
end
