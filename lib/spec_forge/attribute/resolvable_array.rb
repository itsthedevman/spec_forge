# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents an Array that may contain Attributes
    #
    class ResolvableArray < SimpleDelegator
      include Resolvable

      def value
        __getobj__
      end

      def resolve
        value.map(&resolvable_proc)
      end

      def bind_variables(variables)
        value.each { |v| Attribute.bind_variables(v, variables) }
      end
    end
  end
end
