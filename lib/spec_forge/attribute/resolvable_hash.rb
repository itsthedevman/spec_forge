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
    #   resolvable.resolve # => {name: "John Smith", id: 123}
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
      # Resolves all values in the hash that respond to resolve
      #
      # @return [Hash] A new hash with all values resolved
      #
      def resolve
        value.transform_values(&resolvable_proc)
      end

      #
      # Resolves all values in the hash using resolve_value
      #
      # @return [Hash] A new hash with all values resolved using resolve_value
      #
      def resolve_value
        value.transform_values(&resolvable_value_proc)
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
