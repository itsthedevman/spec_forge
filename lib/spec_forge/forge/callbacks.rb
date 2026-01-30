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
      #
      # Creates a new empty callback registry
      #
      # @return [Callbacks] A new callbacks instance
      #
      def initialize
        @callbacks = {}
      end

      #
      # Registers a callback with the given name
      #
      # @param name [String, Symbol] The name to register the callback under
      #
      # @yield The block to execute when the callback is invoked
      #
      # @raise [ArgumentError] If no block is provided
      #
      def register(name, &block)
        raise ArgumentError, "A block must be provided" unless block.is_a?(Proc)

        if registered?(name)
          warn("Callback #{name.in_quotes} is already registered. It will be overwritten")
        end

        @callbacks[name.to_sym] = block
      end

      #
      # Checks if a callback with the given name has been registered
      #
      # @param name [String, Symbol] The callback name to check
      #
      # @return [Boolean] Whether the callback is registered
      #
      def registered?(name)
        @callbacks.key?(name.to_sym)
      end

      #
      # Executes a registered callback by name
      #
      # @param name [String, Symbol] The callback name to execute
      # @param context [Forge::Context, nil] The current execution context
      # @param arguments [Array, Hash] Arguments to pass to the callback
      #
      # @return [Object] The return value of the callback
      #
      # @raise [Error::UndefinedCallbackError] If the callback is not registered
      #
      def run(name, context = nil, arguments = [])
        raise Error::UndefinedCallbackError.new(name, @callbacks.keys) unless registered?(name)

        callback = @callbacks[name.to_sym]

        # No arguments? Just call
        return callback.call if callback.arity == 0
        return callback.call(context) if callback.arity == 1

        case arguments
        when Array
          callback.call(context, *arguments)
        when Hash
          callback.call(context, **arguments)
        end
      end
    end
  end
end
