# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents a hash that may contain Attributes
    #
    class ResolvableHash < SimpleDelegator
      include Resolvable

      def value
        __getobj__
      end

      def resolve
        value.transform_values(&resolvable_proc)
      end

      def resolve_value
        value.transform_values(&resolvable_value_proc)
      end

      def bind_variables(variables)
        value.each_value { |v| Attribute.bind_variables(v, variables) }
      end
    end
  end
end
