# frozen_string_literal: true

module SpecForge
  class Attribute
    class Variable < Attribute
      KEYWORD_REGEX = /^variables\./i
      NUMBER_REGEX = /^\d+$/i

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

      attr_reader :variable_name, :invocation_chain, :variable_value

      # <keyword>.<variable_name>.<hash_key | method | index>
      def initialize(...)
        super

        # Drop the keyword
        sections = input.split(".")[1..]

        @variable_name = sections.first&.to_sym
        @invocation_chain = sections[1..] || []
      end

      def update_value!(lookup_table)
        if !(lookup_table.is_a?(Hash) || lookup_table.is_a?(ResolvableHash))
          raise InvalidTypeError.new(lookup_table, Hash, for: "'variables'")
        end

        # No nil check here.
        raise MissingVariableError, variable_name unless lookup_table.key?(variable_name)

        @variable_value = lookup_table[variable_name]
        self
      end

      def value
        invoke_chain
      end

      private

      def invoke_chain
        current_value = @variable_value

        invocation_chain.each do |step|
          object = retrieve_value(current_value)
          current_value = invoke(step, object)
        end

        retrieve_value(current_value)
      end

      def retrieve_value(object)
        object.is_a?(Attribute) ? object.value : object
      end

      def invoke(step, object)
        if hash_key?(object, step)
          object[step.to_sym]
        elsif index?(object, step)
          object[step.to_i]
        elsif method?(object, step)
          object.public_send(step)
        else
          raise InvalidInvocationError.new(step, object)
        end
      end

      def hash_key?(object, key)
        (
          object.is_a?(Hash) || object.is_a?(ResolvableHash)
        ) && object.key?(key.to_sym)
      end

      def method?(object, method_name)
        object.respond_to?(method_name)
      end

      def index?(object, step)
        (
          object.is_a?(Array) || object.is_a?(ResolvableArray)
        ) && step.match?(NUMBER_REGEX)
      end
    end
  end
end
