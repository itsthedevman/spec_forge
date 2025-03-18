# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents an attribute that references a variable
    #
    # This class allows referencing variables defined in the test context.
    # It supports chained access to methods and properties of variable values.
    #
    # @example Basic usage in YAML
    #   user_id: variables.user.id
    #   company_name: variables.company.name
    #
    # @example Nested access in YAML
    #   post_author: variables.post.comments.first.author.name
    #
    class Variable < Attribute
      include Chainable

      #
      # Regular expression pattern that matches attribute keywords with this prefix
      # Used for identifying this attribute type during parsing
      #
      # @return [Regexp]
      #
      KEYWORD_REGEX = /^variables\./i

      alias_method :variable_name, :header

      #
      # Binds the referenced variable to this attribute
      #
      # @param variables [Hash] A hash of variables to look up in
      #
      # @raise [Error::MissingVariableError] If the variable is not found
      # @raise [Error::InvalidTypeError] If variables is not a hash
      #
      def bind_variables(variables)
        if !Type.hash?(variables)
          raise Error::InvalidTypeError.new(variables, Hash, for: "'variables'")
        end

        # Don't nil check here.
        raise Error::MissingVariableError, variable_name unless variables.key?(variable_name)

        @variable = variables[variable_name]
      end

      #
      # Returns the base object for the variable chain
      #
      # @return [Object] The variable value
      #
      def base_object
        @variable || bind_variables(SpecForge.context.variables.resolved)
      end
    end
  end
end
