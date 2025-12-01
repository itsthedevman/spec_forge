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

        name = name.to_sym
        if @callbacks.key?(name)
          warn("Callback #{name.in_quotes} is already registered. It will be overwritten")
        end

        @callbacks[name] = block
      end

      def register_event(event_name, callback_name:, arguments: nil)
        if !@events.key?(event_name.to_sym)
          event_names = @events.keys.join_map(", ", &:in_quotes)
          raise ArgumentError, "Invalid event name given: #{event_name.in_quotes}. Expected one of: #{event_names}"
        end

        callback_name = callback_name.to_sym
        check_for_registered_callback!(callback_name)

        @events[event_name] << {callback_name:, arguments:}
      end

      private

      def check_for_registered_callback!(callback_name)
        return if @callbacks.key?(callback_name)

        raise Error::UndefinedCallbackError.new(callback_name, @callbacks.keys)
      end
    end
  end
end
