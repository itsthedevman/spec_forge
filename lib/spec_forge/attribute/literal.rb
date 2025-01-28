# frozen_string_literal: true

module SpecForge
  class Attribute
    class Literal < Attribute
      def value
        @input
      end
    end
  end
end
