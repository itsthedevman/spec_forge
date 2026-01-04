# frozen_string_literal: true

module SpecForge
  class Forge
    class Call < Action
      def run(forge)
        forge.display.action(:call, "Call #{step.call.callback_name.in_quotes}", color: :yellow)

        context = SpecForge::Forge.context
        forge.callbacks.run(step.call.callback_name, context, *step.call.arguments)
      end
    end
  end
end
