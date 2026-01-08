# frozen_string_literal: true

module SpecForge
  class Forge
    #
    # Manages registered callbacks that can be invoked from blueprints
    #
    # Callbacks are Ruby blocks registered in forge_helper.rb that can be
    # called during step execution using the call: attribute.
    #
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

      #
      # Executes a registered callback with the given arguments
      #
      # @param name [String, Symbol] The callback name
      # @param arguments [Array] Positional arguments to pass
      # @param keyword_arguments [Hash] Keyword arguments to pass
      #
      # @return [Object] The callback's return value
      #
      # @raise [Error::UndefinedCallbackError] If the callback is not registered
      #
      def run(name, *arguments, **keyword_arguments)
        ensure_registered!(name)

        callback = @callbacks[name.to_sym]
        callback.call(*arguments, **keyword_arguments)
      end

      private

      def ensure_registered!(name)
        return if registered?(name)

        raise Error::UndefinedCallbackError.new(name, @callbacks.keys)
      end
    end
  end
end
