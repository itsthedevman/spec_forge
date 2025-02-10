# frozen_string_literal: true

module SpecForge
  class Attribute
    class Variable < Attribute
      include Chainable

      KEYWORD_REGEX = /^variables\./i

      attr_reader :variable_name

      #
      # Represents any attribute that is a variable reference
      #
      #   variables.<variable_name>
      #
      def initialize(...)
        super

        # Remove the variable name from the chain
        @variable_name = invocation_chain.shift&.to_sym
      end

      def bind_variables(variables)
        raise InvalidTypeError.new(variables, Hash, for: "'variables'") unless Type.hash?(variables)

        # Don't nil check here.
        raise MissingVariableError, variable_name unless variables.key?(variable_name)

        @base_object = variables[variable_name]

        self
      end
    end
  end
end
