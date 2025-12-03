# frozen_string_literal: true

module SpecForge
  class Forge
    class Call < Action
      def run(forge)
        forge.display.action(:call, "Call: #{@step.call.callback_name}", color: :yellow, style: :dim)

        forge.callbacks.run_callback(@step.call.callback_name, @step.call.arguments)
      end
    end
  end
end
