# frozen_string_literal: true

module SpecForge
  class Context
    class Variables < Context
      def initialize
        clear
      end

      def clear
        @inner = {}
      end

      def store(variables)
        @inner = variables.symbolize_keys
      end

      def retrieve(key)
        @inner[key.to_sym]
      end

      alias_method :[], :retrieve
    end
  end
end
