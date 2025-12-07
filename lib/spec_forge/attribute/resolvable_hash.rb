# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents a hash that may contain attributes that need resolution
    #
    # This delegator wraps a hash and provides methods to recursively resolve
    # any attribute objects contained within it. It allows hashes to contain
    # dynamic content like variables and faker values.
    #
    # @example In code
    #   hash = {name: Attribute::Faker.new("faker.name.name"), id: 123}
    #   resolvable = Attribute::ResolvableHash.new(hash)
    #   resolvable.resolved # => {name: "John Smith", id: 123}
    #
    class ResolvableHash < SimpleDelegator
      include Resolvable

      #
      # Returns the underlying hash
      #
      # @return [Hash] The delegated hash
      #
      def value
        __getobj__
      end

      #
      # Returns a new hash with all values fully resolved to their final values.
      # Uses the cached version of each value if available.
      #
      # @return [Hash] A new hash with all values fully resolved to their final values
      #
      # @example
      #   hash_attr = Attribute::ResolvableHash.new({name: Attribute::Faker.new("faker.name.name")})
      #   hash_attr.resolved # => {name: "Jane Doe"} (with result cached)
      #
      def resolved
        value.transform_values(&resolved_proc)
      end

      #
      # Freshly resolves all values in the hash.
      # Unlike #resolved, this doesn't use cached values, ensuring fresh resolution.
      #
      # @return [Hash] A new hash with all values freshly resolved
      #
      # @example
      #   hash_attr = Attribute::ResolvableHash.new({name: Attribute::Faker.new("faker.name.name")})
      #   hash_attr.resolve # => {name: "John Smith"} (fresh value each time)
      #
      def resolve
        value.transform_values(&resolve_proc)
      end

      #
      # Converts all values in the hash to RSpec matchers.
      # Transforms each hash value to a matcher using resolve_as_matcher_proc,
      # then wraps the entire result in a matcher suitable for hash comparison.
      #
      # This ensures proper nesting of matchers in hash structures,
      # which is vital for readable failure messages in complex expectations.
      #
      # @return [RSpec::Matchers::BuiltIn::BaseMatcher] A matcher for this hash
      #
      # @example
      #   hash = Attribute::ResolvableHash.new({name: "Test", age: 42})
      #   hash.resolve_as_matcher # => include("name" => eq("Test"), "age" => eq(42))
      #
      def resolve_as_matcher
        result = value.transform_values(&resolve_as_matcher_proc)
        Attribute::Literal.new(result).resolve_as_matcher
      end
    end
  end
end
