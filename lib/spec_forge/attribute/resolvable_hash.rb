# frozen_string_literal: true

module SpecForge
  class Attribute
    class ResolvableHash < SimpleDelegator
      include Resolvable

      def value
        __getobj__
      end

      def resolve
        value.transform_values(&resolvable_proc)
      end
    end
  end
end
