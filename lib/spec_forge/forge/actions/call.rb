# frozen_string_literal: true

module SpecForge
  class Forge
    class Call < Action
      def run(forge)
        forge.display.action(:call, "Call #{step.call.callback_name.in_quotes}", color: :yellow)

        context = SpecForge::Forge.context
        arguments = step.call.arguments

        case arguments
        when Array
          forge.callbacks.run(step.call.callback_name, context, *arguments)
        when Hash
          forge.callbacks.run(step.call.callback_name, context, **arguments)
        else
          forge.callbacks.run(step.call.callback_name, context)
        end
      end
    end
  end
end
