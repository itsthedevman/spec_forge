# frozen_string_literal: true

module SpecForge
  class Context
    def clear
      raise "not implemented"
    end

    def store(value)
      raise "not implemented"
    end

    def retrieve(value)
      raise "not implemented"
    end

    #
    # Makes getting/setting easier
    # @private
    #
    class Settable
      def initialize(inner)
        set(inner)
      end

      def set(inner)
        @inner = inner
      end

      def get
        @inner
      end
    end
  end
end

require_relative "context/global"
require_relative "context/manager"
require_relative "context/metadata"
require_relative "context/store"
require_relative "context/variables"
