# frozen_string_literal: true

module SpecForge
  class Attribute
    class Variable < Attribute
      include Chainable

      KEYWORD_REGEX = /^variables\./i

      attr_reader :variable_name

      def initialize(...)
        super

        # Remove the variable name from the chain
        @variable_name = invocation_chain.shift&.to_sym
      end

      def bind_variables(variables)
        if !variables.respond_to?(:key?) # I might regret this
          raise InvalidTypeError.new(variables, Hash, for: "'variables'")
        end

        # No nil check here.
        raise MissingVariableError, variable_name unless variables.key?(variable_name)

        @base_object = variables[variable_name]
        self
      end
    end
  end
end
