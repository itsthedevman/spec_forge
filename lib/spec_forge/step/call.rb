# frozen_string_literal: true

module SpecForge
  class Step
    #
    # Represents a callback invocation within a step
    #
    # Holds the callback name and any arguments to pass when the
    # callback is executed during step processing.
    #
    class Call < Data.define(:callback_name, :arguments)
      def self.wrap_hooks(hooks)
        hooks = hooks&.compact_blank
        return {} if hooks.blank?

        hooks.transform_values do |call|
          calls =
            if call.is_a?(Set)
              call.to_a
            else
              Array.wrap(call)
            end

          calls.map { |c| Call.new(callback_name: c[:name], arguments: c[:arguments]) }
        end
      end
    end
  end
end
