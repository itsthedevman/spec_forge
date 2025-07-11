# frozen_string_literal: true

module SpecForge
  #
  # Manages user-defined callbacks for test lifecycle events
  #
  # This singleton class stores and executes callback functions that
  # users can register to run at specific points in the test lifecycle.
  # Each callback receives a context object containing relevant state
  # information for that point in execution.
  #
  # @example Registering and using a callback
  #   SpecForge::Callbacks.register(:my_callback) do |context|
  #     puts "Running test: #{context.expectation_name}"
  #   end
  #
  class Callbacks < Hash
    include Singleton

    class << self
      #
      # Registers a new callback for a specific event
      #
      # @param name [String, Symbol] The name of the callback event
      # @param block [Proc] The callback function to execute
      #
      # @raise [ArgumentError] If no block is provided
      #
      def register(name, &block)
        raise ArgumentError, "A block must be provided" unless block.is_a?(Proc)

        if registered?(name)
          warn("Callback #{name.in_quotes} is already registered. It will be overwritten")
        end

        instance[name.to_s] = block
      end

      #
      # Deregisters a callback
      #
      # @param name [String, Symbol] The name of the callback
      #
      def deregister(name)
        instance.delete(name.to_s)
      end

      #
      # Checks if a callback is registered for the given event
      #
      # @param name [String, Symbol] The name of the callback event
      #
      # @return [Boolean] True if the callback exists
      #
      def registered?(name)
        instance.key?(name.to_s)
      end

      #
      # Returns all registered callback names
      #
      # @return [Array<String>] List of registered callback names
      #
      def registered_names
        instance.keys
      end

      #
      # Executes a named callback with the provided context
      #
      # @param name [String, Symbol] The name of the callback to run
      # @param context [Object] Context object containing state data
      #
      # @raise [ArgumentError] If the callback is not registered
      #
      def run(name, context)
        callback = instance[name.to_s]
        raise ArgumentError, "Callback #{name.in_quotes} is not defined" if callback.nil?

        if callback.arity == 0
          callback.call
        else
          callback.call(context)
        end
      end
    end
  end
end
