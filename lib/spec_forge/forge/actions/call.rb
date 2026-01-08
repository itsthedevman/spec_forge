# frozen_string_literal: true

module SpecForge
  class Forge
    #
    # Action for the `call:` step attribute
    #
    # Executes registered callbacks defined in forge_helper.rb during step processing.
    # Callbacks can receive the current context and optional arguments.
    #
    class Call < Action
      #
      # Executes the callback with appropriate arguments
      #
      # @param forge [Forge] The forge instance
      #
      # @return [Object] The callback's return value
      #
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
