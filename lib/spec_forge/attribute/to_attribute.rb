# frozen_string_literal: true

module SpecForge
  class Attribute
    module ToAttribute
      def to_attribute
        Attribute.from(self)
      end
    end
  end
end
