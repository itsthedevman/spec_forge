# frozen_string_literal: true

module SpecForge
  class Attribute
    module Chainable
      NUMBER_REGEX = /^\d+$/i

      attr_reader :header, :invocation_chain, :base_object

      #
      # Represents any attribute that is a series of chained invocations:
      #
      #   <keyword>.<header>.<segment(hash_key | method | index)>...
      #
      # This module is not used as is, but is included in another class.
      # Note: There can be any n number of segments.
      #
      def initialize(...)
        super

        # Drop the keyword
        sections = input.split(".")[1..]

        @header = sections.first&.to_sym
        @invocation_chain = sections[1..] || []
      end

      def value
        invoke_chain
      end

      def resolve
        @resolved ||= resolve_chain
      end

      private

      def invoke_chain
        traverse_chain(resolve: false)
      end

      def resolve_chain
        __resolve(traverse_chain(resolve: true))
      end

      def traverse_chain(resolve:)
        result = invocation_chain.reduce(base_object) do |current_value, step|
          next_value = retrieve_value(current_value, resolve:)

          invoke(step, next_value)
        end

        retrieve_value(result, resolve:)
      end

      def retrieve_value(object, resolve:)
        return object unless object.is_a?(Attribute)

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
