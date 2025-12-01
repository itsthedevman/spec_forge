# frozen_string_literal: true

module SpecForge
  class Forge
    class Hooks < Action
      def run(forge)
        @step.hooks
          .flat_map(&:to_a)
          .each do |event, hook|
            forge.callbacks.register_event(event, callback_name: hook[:name], arguments: hook[:arguments])
          end
      end
    end
  end
end
