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
      # Binds variables to any attribute objects in the hash values
      #
      # @param variables [Hash] The variables to bind
      #
      def bind_variables(variables)
        value.each_value { |v| Attribute.bind_variables(v, variables) }
      end
    end
  end
end
