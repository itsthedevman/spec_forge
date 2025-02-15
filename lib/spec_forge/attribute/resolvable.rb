# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Helpers for ResolvableHash and ResolvableArray
    #
    module Resolvable
      # @private
      def resolvable_proc
        ->(v) { v.respond_to?(:resolve) ? v.resolve : v }
      end

      def resolvable_value_proc
        ->(v) { v.respond_to?(:resolve_value) ? v.resolve_value : v }
      end
    end
  end
end
