# frozen_string_literal: true

module SpecForge
  class Attribute
    class ResolvableArray < SimpleDelegator
      def value
        __getobj__
      end

      def resolve
        value.map { |v| v.respond_to?(:resolve) ? v.resolve : v }
      end
    end
  end
end
