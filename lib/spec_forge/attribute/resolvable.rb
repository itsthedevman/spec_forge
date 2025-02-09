# frozen_string_literal: true

module SpecForge
  class Attribute
    module Resolvable
      def to_proc
        this = self
        -> { this.resolve }
      end

      def resolvable_proc
        ->(v) { v.respond_to?(:resolve) ? v.resolve : v }
      end
    end
  end
end
