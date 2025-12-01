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

        name = name.to_s
        if @callbacks.key?(name)
          warn("Callback #{name.in_quotes} is already registered. It will be overwritten")
        end

        @callbacks[name] = block
      end

      def register_event(event_name, callback_name, arguments: nil)
        if !@events.key?(event_name)
          event_names = @events.keys.join_map(", ", &:in_quotes)
          raise ArgumentError, "Invalid event name given: #{event_name.in_quotes}. Expected one of: #{event_names}"
        end

        @events[event_name] << {callback_name:, arguments:}
      end
    end
  end
end
