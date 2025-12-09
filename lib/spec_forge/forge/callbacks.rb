# frozen_string_literal: true

module SpecForge
  class Forge
    class Callbacks
      def initialize
        @callbacks = {}
      end

      def register(name, &block)
        raise ArgumentError, "A block must be provided" unless block.is_a?(Proc)

        if registered?(name)
          warn("Callback #{name.in_quotes} is already registered. It will be overwritten")
        end

        @callbacks[name.to_sym] = block
      end

      def registered?(name)
        @callbacks.key?(name.to_sym)
      end

      def run(name, arguments = nil, before_block: nil)
        ensure_registered!(name)

        callback = @callbacks[name.to_sym]
        callback.call(*arguments)
      end

      private

      def ensure_registered!(name)
        return if registered?(name)

        raise Error::UndefinedCallbackError.new(name, @callbacks.keys)
      end
    end
  end
end
