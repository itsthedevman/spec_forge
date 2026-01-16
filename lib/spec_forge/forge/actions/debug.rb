# frozen_string_literal: true

module SpecForge
  class Forge
    #
    # Action for the `debug:` step attribute
    #
    # Triggers a debug breakpoint when a step has debug: true, invoking the
    # configured debug handler (e.g., binding.pry) to allow interactive debugging.
    #
    class Debug < Action
      #
      # Triggers the debug breakpoint
      #
      # @param forge [Forge] The forge instance
      #
      # @return [void]
      #
      # @raise [Error] If no debug handler is configured
      #
      def run(forge)
        forge.display.action("Debug breakpoint triggered", symbol: :flag, symbol_styles: :yellow)

        callback = SpecForge.configuration.on_debug_proc
        if callback.nil?
          raise Error, <<~STRING
            Debug breakpoint triggered but no debug handler is configured.

            Add a debug handler in your forge_helper.rb:

              SpecForge.configure do |config|
                config.on_debug { binding.pry }  # or byebug, debug, etc.
              end

          STRING
        end

        callback.call(SpecForge::Forge.context)
      end
    end
  end
end
