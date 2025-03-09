# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents an array that may contain attributes that need resolution
    #
    # This delegator wraps an array and provides methods to recursively resolve
    # any attribute objects contained within it. It allows arrays to contain
    # dynamic content like variables and faker values.
    #
    # @example In code
    #   array = [1, Attribute::Variable.new("variables.user_id"), 3]
    #   resolvable = Attribute::ResolvableArray.new(array)
    #   resolvable.resolve # => [1, 42, 3]  # assuming user_id resolves to 42
    #
    class ResolvableArray < SimpleDelegator
      include Resolvable

      #
      # Returns the underlying array
      #
      # @return [Array] The delegated array
      #
      def value
        __getobj__
      end

      #
      # Resolves all items in the array that respond to resolve
      #
      # @return [Array] A new array with all items resolved
      #
      def resolve
        value.map(&resolvable_proc)
      end

      #
      # Resolves all items in the array using resolve_value
      #
      # @return [Array] A new array with all items resolved using resolve_value
      #
      def resolve_value
        value.map(&resolvable_value_proc)
      end

      #
      # Binds variables to any attribute objects in the array
      #
      # @param variables [Hash] The variables to bind
      #
      def bind_variables(variables)
        value.each { |v| Attribute.bind_variables(v, variables) }
      end
    end
  end
end
