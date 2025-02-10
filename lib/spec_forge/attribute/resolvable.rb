# frozen_string_literal: true

module SpecForge
  class Attribute
    module Resolvable
      # @private
      def to_proc
        this = self
        -> { this.resolve }
      end

      # @private
      def resolvable_proc
        ->(v) { v.respond_to?(:resolve) ? v.resolve : v }
      end
    end
  end
end
