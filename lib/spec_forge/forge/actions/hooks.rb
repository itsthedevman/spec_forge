# frozen_string_literal: true

module SpecForge
  class Forge
    class Hooks < Action
      def run(forge)
        step.hooks.each do |hook|
          forge.display.action(:hook, "#{hook.event}: #{hook.callback_name}", color: :bright_magenta)

          forge.callbacks.register_event(hook.event, callback_name: hook.callback_name, arguments: hook.arguments)
        end
      end
    end
  end
end
