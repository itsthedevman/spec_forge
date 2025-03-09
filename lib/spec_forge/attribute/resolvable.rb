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
      # Returns a proc that resolves attributes using the resolve method
      #
      # @return [Proc] A proc that calls resolve on objects that respond to it
      #
      def resolvable_proc
        ->(v) { v.respond_to?(:resolve) ? v.resolve : v }
      end

      #
      # Returns a proc that resolves attributes using the resolve_value method
      #
      # @return [Proc] A proc that calls resolve_value on objects that respond to it
      #
      def resolvable_value_proc
        ->(v) { v.respond_to?(:resolve_value) ? v.resolve_value : v }
      end
    end
  end
end
