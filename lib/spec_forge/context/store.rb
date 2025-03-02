# frozen_string_literal: true

module SpecForge
  class Context
    class Store < Context
      def initialize
        clear
      end

      def clear
        @inner = {}
      end

      def store(key, value)
        @inner[key.to_sym] = value
      end

      def retrieve(key)
        @inner[key.to_sym]
      end

      alias_method :[], :retrieve
    end
  end
end
