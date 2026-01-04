# frozen_string_literal: true

module SpecForge
  class Forge
    class Debug < Action
      def run(forge)
        forge.display.action(:debug, "Debug breakpoint triggered", color: :yellow)

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
