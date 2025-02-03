# frozen_string_literal: true

module SpecForge
  class Attribute
    class Resolvable < SimpleDelegator
      def resolve
        object = __getobj__

        case object
        when Array
          object.map { |v| v.is_a?(Attribute) ? v.resolve : v }
        when Hash
          object.transform_values { |v| v.is_a?(Attribute) ? v.resolve : v }
        when Attribute
          object.resolve
        else
          object
        end
      end
    end
  end
end
