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
      # Converts all items in the array to RSpec matchers.
      # First converts each array element to a matcher using resolve_as_matcher_proc,
      # then wraps the entire result in a matcher suitable for array comparison.
      #
      # This ensures all elements in the array are proper matchers,
      # which is essential for compound matchers and proper failure messages.
      #
      # @return [RSpec::Matchers::BuiltIn::BaseMatcher] A matcher for this array
      #
      # @example
      #   array = Attribute::ResolvableArray.new(["test", /pattern/, 42])
      #   array.resolve_as_matcher # => contain_exactly(eq("test"), match(/pattern/), eq(42))
      #
      def resolve_as_matcher
        result = value.map(&resolve_as_matcher_proc)
        Attribute::Literal.new(result).resolve_as_matcher
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
