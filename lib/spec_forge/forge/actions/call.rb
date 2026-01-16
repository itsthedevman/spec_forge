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
      # TODO: Documentation
      def run(forge)
        context = SpecForge::Forge.context

        step.calls.each do |call|
          callback_name = call.callback_name
          arguments = call.arguments

          forge.display.action("Call #{callback_name}", symbol: :checkmark, symbol_styles: :yellow)

          forge.callbacks.run(callback_name, context, arguments)
        end
      end
    end
  end
end
