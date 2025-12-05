# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Adds support for an attribute to accept n-number of chained calls. It supports chaining
    # methods, hash keys, and array indexes. It also works well alongside Parameterized attributes
    #
    # This module requires being included into a class first before it can be used
    #
    # @example Basic usage in YAML
    #   my_variable: variable.users.first
    #
    # @example Advanced usage in YAML
    #   my_variable: variable.users.0.posts.second.author.name
    #
    # @example Basic usage in code
    #   faker = SpecForge::Attribute.from("faker.name.name.upcase")
    #   faker.resolved #=> BENDING UNIT 22
    #
    module Chainable
      #
      # Regular expression that matches pure numeric strings
      # Used for detecting potential array index operations
      #
      # @return [Regexp] A case-insensitive regex matching strings containing only digits
      #
      NUMBER_REGEX = /^\d+$/i

      #
      # The first part of the chained attribute
      #
      # @return [Symbol] The first component of the chained attribute
      #
      attr_reader :keyword

      #
      # The second part of the chained attribute
      #
      # @return [Symbol] The second component of the chained attribute
      #
      attr_reader :header

      #
      # The remaining parts of the attribute chain after the header
      #
      # @return [Array<Symbol>] The remaining method/key invocations in the chain
      #
      attr_reader :invocation_chain

      #
      # The initial object from which the chain will start traversing
      #
      # @return [Object] The base object that starts the method/attribute chain
      #
      attr_reader :base_object

      #
      # Initializes a new chainable attribute by parsing the input into components
      #
      def initialize(...)
        super

        sections = input.split(".")

        @keyword = sections.first.to_sym
        @header = sections.second&.to_sym
        @invocation_chain = sections[2..] || []
      end

      #
      # Returns the value of this attribute by resolving the chain
      # Will return a new value on each call for dynamic attributes like Faker
      #
      # @return [Object] The result of invoking the chain on the base object
      #
      def value
        invoke_chain
      end

      #
      # Resolves the chain and stores the result
      # The result is memoized, so subsequent calls return the same value
      # even for dynamic attributes like Faker and Factory
      #
      # @return [Object] The fully resolved and memoized value
      #
      def resolved
        @resolved ||= resolve_chain
      end

      private

      #
      # Invokes the chain by calling #value on each object
      #
      # @return [Object] The result of invoking the chain
      #
      # @private
      #
      def invoke_chain
        traverse_chain(resolve: false)
      end

      #
      # Resolves the chain by calling #resolve on each object
      #
      # @return [Object] The fully resolved result
      #
      # @private
      #
      def resolve_chain
        traverse_chain(resolve: true)
      end

      #
      # Traverses the chain of invocations step by step
      #
      # @param resolve [Boolean] Whether to use resolve during traversal
      #
      # @return [Object] The result of the traversal
      #
      # @private
      #
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
        rescue Error::InvalidInvocationError => e
          resolution_path[current_path] = "Error: #{e.message}"

          raise e.with_resolution_path(resolution_path)
        end

        # Return final result
        retrieve_value(current_object, resolve:)
      end

      #
      # Retrieves the value from an object, resolving it if needed
      #
      # @param object [Object] The object to retrieve a value from
      # @param resolve [Boolean] Whether to resolve the object's value
      #
      # @return [Object] The retrieved value
      #
      # @private
      #
      def retrieve_value(object, resolve:)
        return object unless object.is_a?(Attribute)

        resolve ? object.resolved : object.value
      end

      #
      # Creates a description of a value for error messages
      #
      # @param value [Object] The value to describe
      #
      # @return [String] A description
      #
      # @private
      #
      def describe_value(value)
        case value
        when OpenStruct
          "Object with attributes: #{value.table.keys.join_map(", ", &:in_quotes)}"
        when Struct, Data
          "Object with attributes: #{value.members.join_map(", ", &:in_quotes)}"
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
        when Proc
          "Proc defined at #{value.source_location.join(":")}"
        else
          "#{value.class}: #{value.inspect[0..50]}"
        end
      end

      #
      # Invokes an operation on an object based on the step type (hash key, array index, or method)
      #
      # @param step [String] The step to invoke
      # @param object [Object] The object to invoke the step on
      #
      # @return [Object] The result of the invocation
      #
      # @raise [Error::InvalidInvocationError] If the step cannot be invoked on the object
      #
      # @private
      #
      def invoke(step, object)
        if hash_key?(object, step)
          object[step.to_s] || object[step.to_sym]
        elsif index?(object, step)
          object[step.to_i]
        elsif method?(object, step)
          object.public_send(step)
        else
          raise Error::InvalidInvocationError.new(step, object)
        end
      end

      #
      # Checks if the object can be accessed with the given key
      #
      # @param object [Object] The object to check
      # @param key [String] The key to check
      #
      # @return [Boolean] Whether the object supports hash-like access with the key
      #
      # @private
      #
      def hash_key?(object, key)
        # This is to support the silly delegator and both symbol/string
        method?(object, :key?) && (object.key?(key.to_s) || object.key?(key.to_sym))
      end

      #
      # Checks if the object responds to the given method
      #
      # @param object [Object] The object to check
      # @param method_name [String, Symbol] The method name to check
      #
      # @return [Boolean] Whether the object responds to the method
      #
      # @private
      #
      def method?(object, method_name)
        object.respond_to?(method_name)
      end

      #
      # Checks if the object supports array-like access with the given index
      #
      # @param object [Object] The object to check
      # @param step [String] The potential index
      #
      # @return [Boolean] Whether the object supports array-like access with the step
      #
      # @private
      #
      def index?(object, step)
        # This is to support the silly delegator
        method?(object, :index) && step.match?(NUMBER_REGEX)
      end
    end
  end
end
