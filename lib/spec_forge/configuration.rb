# frozen_string_literal: true

module SpecForge
  CONFIG_ATTRIBUTES = []

  class Configuration < Struct.new(*CONFIG_ATTRIBUTES)
    include Singleton

    def self.configure(&)
      instance.configure(&)
    end

    def configure(&block)
      yield(self) if block
      self
    end
  end
end
