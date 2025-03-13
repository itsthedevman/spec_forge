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
    #   resolvable.resolved # => [1, 42, 3]  # assuming user_id resolves to 42
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
      # Returns a new array with all items fully resolved to their final values.
      # Uses the cached version of each item if available.
      #
      # @return [Array] A new array with all items fully resolved to their final values
      #
      # @example
      #   array_attr = Attribute::ResolvableArray.new([Attribute::Faker.new("faker.name.name")])
      #   array_attr.resolved # => ["Jane Doe"] (with result cached)
      #
      def resolved
        value.map(&resolved_proc)
      end

      #
      # Freshly resolves all items in the array.
      # Unlike #resolved, this doesn't use cached values, ensuring fresh resolution.
      #
      # @return [Array] A new array with all items freshly resolved
      #
      # @example
      #   array_attr = Attribute::ResolvableArray.new([Attribute::Faker.new("faker.name.name")])
      #   array_attr.resolve # => ["John Smith"] (fresh value each time)
      #
      def resolve
        value.map(&resolve_proc)
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
