# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents a variable reference in a template
    #
    # Variables are resolved at runtime by looking up values stored in the
    # current execution context. Supports dot notation for accessing nested
    # properties (e.g., "response.body.id").
    #
    # @example Simple variable
    #   Variable.new("user_id")  # Looks up :user_id in context
    #
    # @example Nested access
    #   Variable.new("response.body.token")  # response[:body][:token]
    #
    class Variable < Attribute
      include Chainable

      alias_method :variable_name, :header

      def initialize(input)
        super

        # Unset the keyword to keep chainable from displaying it in error messages
        @keyword = nil

        sections = input.split(".")
        @header = sections.first&.to_sym
        @invocation_chain = sections[1..] || []
      end

      #
      # Returns the base object for this variable from the current context
      #
      # Looks up the variable name in the current Forge context's variables.
      # Raises an error if the variable is not defined.
      #
      # @return [Object] The value stored under this variable name
      #
      # @raise [Error::MissingVariableError] If the variable is not defined
      #
      def base_object
        @base_object ||= begin
          variables = Forge.context&.variables || {}

          if !variables.key?(variable_name)
            raise Error::MissingVariableError.new(variable_name, available_variables: variables.keys)
          end

          variables[variable_name]
        end
      end
    end
  end
end
