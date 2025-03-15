# frozen_string_literal: true

module SpecForge
  class Callbacks < Hash
    include Singleton

    def self.register(name, &block)
      raise ArgumentError, "A block must be provided" unless block.is_a?(Proc)

      if instance.key?(name)
        warn("Callback #{name.in_quotes} is already registered. It will be overwritten")
      end

      instance[name] = block
    end
  end
end
