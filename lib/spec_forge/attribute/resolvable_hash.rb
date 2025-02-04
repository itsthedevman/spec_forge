# frozen_string_literal: true

module SpecForge
  class Attribute
    class ResolvableHash < SimpleDelegator
      def value
        __getobj__
      end

      def resolve
        value.transform_values { |v| v.respond_to?(:resolve) ? v.resolve : v }
      end
    end
  end
end
