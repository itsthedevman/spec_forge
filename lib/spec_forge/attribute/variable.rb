# frozen_string_literal: true

module SpecForge
  class Attribute
    class Variable < Attribute
      include Chainable

      KEYWORD_REGEX = /^[\w.]+$/

      alias_method :variable_name, :header

      def initialize(input)
        super

        sections = input.split(".")
        @header = sections.first&.to_sym
        @invocation_chain = sections[1..] || []
      end

      def bind_variables(variables)
        if !Type.hash?(variables)
          raise Error::InvalidTypeError.new(variables, Hash, for: "'variables'")
        end

        # Don't nil check here.
        raise Error::MissingVariableError, variable_name unless variables.key?(variable_name)

        @variable = variables[variable_name]
      end

      def base_object
        @variable || Forge.context&.local_variables&.[](@header)
      end
    end
  end
end
