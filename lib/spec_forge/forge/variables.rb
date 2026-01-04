# frozen_string_literal: true

module SpecForge
  class Forge
    class Variables < Hash
      def initialize(static: {}, dynamic: {})
        @static = static.deep_dup

        merge!(@static, dynamic.deep_dup)
      end

      def clear
        super
        merge!(@static)
      end
    end
  end
end
