# frozen_string_literal: true

module SpecForge
  class Attribute
    module Chainable
      NUMBER_REGEX = /^\d+$/i

      attr_reader :keyword, :header, :invocation_chain, :base_object

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

        sections = input.split(".")

        @keyword = sections.first.to_sym
        @header = sections.second&.to_sym
        @invocation_chain = sections[2..] || []
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
        resolution_path = {}

        current_path = "#{keyword}.#{header}"
        current_object = base_object

        invocation_chain.each do |step|
          next_value = retrieve_value(current_object, resolve:)

          # Store this step's resolution for error reporting
          resolution_path[current_path] = describe_value(next_value)
          current_path += ".#{step}"

          # Try to invoke the next step
          current_object = invoke(step, next_value)
        rescue InvalidInvocationError => e
          resolution_path[current_path] = "Error: #{e.message}"

          raise e.with_resolution_path(resolution_path)
        end

        # Return final result
        retrieve_value(current_object, resolve:)
      end

      def retrieve_value(object, resolve:)
        return object unless object.is_a?(Attribute)

        resolve ? object.resolve : object.value
      end

      def describe_value(value)
        case value
        when ArrayLike
          # Preview the first 5 value's classes
          preview = value.take(5).map(&:class)
          preview << "..." if value.size > 5

          "Array with #{value.size} #{"element".pluralize(value.size)}: #{preview}"
        when HashLike
          # Preview the first 5 keys
          keys = value.keys.take(5)

          preview = keys.join_map(", ") { |key| "\"#{key}\"" }
          preview += ", ..." if value.keys.size > 5

          "Hash with #{"key".pluralize(keys.size)}: #{preview}"
        when String
          "\"#{value.truncate(50)}\""
        when NilClass
          "nil"
        else
          "#{value.class}: #{value.inspect[0..50]}"
        end
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
