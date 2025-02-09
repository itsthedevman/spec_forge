# frozen_string_literal: true

module SpecForge
  class Attribute
    class ResolvableArray < SimpleDelegator
      include Resolvable

      def value
        __getobj__
      end

      def resolve
        value.map(&resolvable_proc)
      end
    end
  end
end
