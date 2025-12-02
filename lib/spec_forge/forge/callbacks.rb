# frozen_string_literal: true

module SpecForge
  class Forge
    class Callbacks
      def initialize
        @callbacks = {}

        @events = {
          before_each: [],
          after_each: [],
          before_file: [],
          after_file: []
        }
      end

      def register_callback(name, &block)
        raise ArgumentError, "A block must be provided" unless block.is_a?(Proc)

        if callback_registered?(name)
          warn("Callback #{name.in_quotes} is already registered. It will be overwritten")
        end

        @callbacks[name.to_sym] = block
      end

      def register_event(event_name, callback_name:, arguments: nil)
        if !@events.key?(event_name.to_sym)
          event_names = @events.keys.join_map(", ", &:in_quotes)
          raise ArgumentError, "Invalid event name given: #{event_name.in_quotes}. Expected one of: #{event_names}"
        end

        callback_name = callback_name.to_sym
        ensure_callback_registered!(callback_name)

        @events[event_name] << {callback_name:, arguments:}
      end

      def callback_registered?(callback_name)
        @callbacks.key?(callback_name.to_sym)
      end

      def run_callback(name, arguments = nil)
        ensure_callback_registered!(name)

        callback = @callbacks[name.to_sym]
        if callback.arity == 1
          callback.call(arguments)
        else
          callback.call
        end
      end

      private

      def ensure_callback_registered!(callback_name)
        return if callback_registered?(callback_name)

        raise Error::UndefinedCallbackError.new(callback_name, @callbacks.keys)
      end
    end
  end
end
