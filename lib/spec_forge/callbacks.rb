# frozen_string_literal: true

module SpecForge
  class Callbacks < Hash
    include Singleton

    class << self
      def register(name, &block)
        raise ArgumentError, "A block must be provided" unless block.is_a?(Proc)

        if registered?(name)
          warn("Callback #{name.in_quotes} is already registered. It will be overwritten")
        end

        instance[name.to_s] = block
      end

      def registered?(name)
        instance.key?(name.to_s)
      end

      def registered_names
        instance.keys
      end

      def run_callback(name, arguments = [])
        callback = instance[name.to_s]
        raise ArgumentError, "Callback #{name.in_quotes} is not defined" if callback.nil?

        callback.call(*arguments)
      end
    end
  end
end
