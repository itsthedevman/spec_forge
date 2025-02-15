# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents any attribute that is a variable reference
    #
    #   variables.<variable_name>
    #
    class Variable < Attribute
      include Chainable

      KEYWORD_REGEX = /^variables\./i

      alias_method :variable_name, :header

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
