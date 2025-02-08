# frozen_string_literal: true

module SpecForge
  class Attribute
    module Chainable
      NUMBER_REGEX = /^\d+$/i

      attr_reader :invocation_chain, :base_object

      # <keyword>.<header>.<hash_key | method | index>...
      def initialize(...)
        super

        # Drop the keyword
        sections = input.split(".")[1..]

        # The "header" is the first element in this array
        @invocation_chain = sections || []
      end

      def value
        invoke_chain
      end

      #
      # Custom implementation to ensure the underlying values are resolved
      # without breaking #value's functionality
      #
      def resolve
        @resolved ||= __resolve(invoke_chain(resolve: true))
      end

      private

      def invoke_chain(resolve: false)
        current_value = @base_object

        invocation_chain.each do |step|
          object = retrieve_value(current_value, resolve:)
          current_value = invoke(step, object)
        end

        retrieve_value(current_value, resolve:)
      end

      def retrieve_value(object, resolve: false)
        return object if !object.is_a?(Attribute)

        resolve ? object.resolve : object.value
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
        # This is to support the silly delegator
        method?(object, :key?) && object.key?(key.to_sym)
      end

      def method?(object, method_name)
        object.respond_to?(method_name)
      end

      def index?(object, step)
        # This is to support the silly delegator
        method?(object, :index) && step.match?(NUMBER_REGEX)
      end
    end
  end
end
