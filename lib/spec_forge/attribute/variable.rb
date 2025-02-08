# frozen_string_literal: true

module SpecForge
  class Attribute
    class Variable < Attribute
      include Chainable

      KEYWORD_REGEX = /^variables\./i

      def self.update_value!(value, variables)
        case value
        when Array, ResolvableArray
          value.each { |v| update_value!(v, variables) }
        when Hash, ResolvableHash
          value.each_value { |v| update_value!(v, variables) }
        when self
          value.update_value!(variables)
        end

        value
      end

      attr_reader :variable_name, :variable_value

      def initialize(...)
        super

        # Remove the variable name from the chain
        @variable_name = invocation_chain.shift&.to_sym
      end

      def update_value!(lookup_table)
        if !lookup_table.respond_to?(:key?) # I might regret this
          raise InvalidTypeError.new(lookup_table, Hash, for: "'variables'")
        end

        # No nil check here.
        raise MissingVariableError, variable_name unless lookup_table.key?(variable_name)

        @variable_value = lookup_table[variable_name]
        self
      end
    end
  end
end
