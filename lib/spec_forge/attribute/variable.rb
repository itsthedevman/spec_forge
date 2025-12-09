# frozen_string_literal: true

module SpecForge
  class Attribute
    class Variable < Attribute
      include Chainable

      alias_method :variable_name, :header

      def initialize(input)
        super

        @keyword = nil

        sections = input.split(".")
        @header = sections.first&.to_sym
        @invocation_chain = sections[1..] || []
      end

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
