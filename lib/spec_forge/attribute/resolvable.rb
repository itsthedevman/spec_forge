# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Provides helper methods for resolving attributes
    #
    # This module contains shared logic for handling attribute resolution
    # in collection types. It defines procs that can be used with map and
    # transform operations to recursively resolve nested attributes.
    #
    module Resolvable
      #
      # Returns a proc that resolves objects to their cached final values.
      # For objects that respond to #resolved, calls that method.
      # For other objects, simply returns them unchanged.
      #
      # @return [Proc] A proc for resolving objects to their cached final values
      #
      # @example
      #   proc = resolved_proc
      #   proc.call(Attribute::Faker.new("faker.name.name")) # => "Jane Doe" (cached)
      #   proc.call("already resolved") # => "already resolved" (unchanged)
      #
      def resolved_proc
        ->(v) { v.respond_to?(:resolved) ? v.resolved : v }
      end

      #
      # Returns a proc that freshly resolves objects.
      # For objects that respond to #resolve, calls that method.
      # For other objects, simply returns them unchanged.
      #
      # @return [Proc] A proc for freshly resolving objects
      #
      # @example
      #   proc = resolve_proc
      #   proc.call(Attribute::Faker.new("faker.name.name")) # => "John Smith" (fresh)
      #   proc.call("already resolved") # => "already resolved" (unchanged)
      #
      def resolve_proc
        ->(v) { v.respond_to?(:resolve) ? v.resolve : v }
      end
    end
  end
end
