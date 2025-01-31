# frozen_string_literal: true

module SpecForge
  class Attribute
    class Variable < Attribute
      NUMBER_REGEX = /\d+/i

      attr_reader :variable_name, :invocation_chain, :lookup_table

      # <keyword>.<variable_name>.<hash_key | method | index>
      def initialize(...)
        super

        # Drop the keyword
        sections = input.split(".")[1..]

        @variable_name = sections.first.to_s
        @invocation_chain = sections[1..]

        @lookup_table = {}
      end

      def update_lookup_table(variables_hash)
        @lookup_table = variables_hash.with_indifferent_access
        self
      end

      def value
        variable = lookup_table[@variable_name]
        invoke_chain(variable)
      end

      private

      def invoke_chain(variable_attribute)
        current_value = variable_attribute

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
        if hash_key?(object, step) || index?(object, step)
          object[step]
        elsif method?(object, step)
          object.public_send(step)
        else
          raise InvalidInvocationError.new(step, object)
        end
      end

      def hash_key?(object, key)
        object.is_a?(Hash) && object.with_indifferent_access.key?(key)
      end

      def method?(object, method_name)
        object.respond_to?(method_name)
      end

      def index?(object, step)
        object.is_a?(Array) && step.match?(NUMBER_REGEX)
      end
    end
  end
end
