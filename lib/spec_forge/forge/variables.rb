# frozen_string_literal: true

module SpecForge
  class Forge
    class Variables
      def initialize(static: {}, dynamic: {})
        @static = static.deep_dup.with_indifferent_access
        @dynamic = dynamic.deep_dup.with_indifferent_access
      end

      def clear
        @dynamic = {}
      end

      def [](name)
        @dynamic[name] || @static[name]
      end

      alias_method :fetch, :[]

      def []=(name, value)
        @dynamic[name] = value
      end

      alias_method :store, :[]=

      def remove_all(*keys)
        @dynamic.except!(*keys)
      end
    end
  end
end
