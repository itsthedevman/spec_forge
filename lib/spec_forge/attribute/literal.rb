# frozen_string_literal: true

module SpecForge
  class Attribute
    class Literal < Attribute
      def value
        case input
        when Array
          input.map { |v| Attribute.from(v) }
        else
          input
        end
      end
    end
  end
end
