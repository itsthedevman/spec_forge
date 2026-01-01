# frozen_string_literal: true

module SpecForge
  class Forge
    class Debug < Action
      def self.default
        lambda do
          # TODO
          puts <<~STRING

            Debug triggered for:
          STRING

          puts inspect
        end
      end

      def run(forge)
        forge.display.action(:debug, "Debug breakpoint triggered", color: :orange)

        callback = SpecForge.configuration.on_debug_proc
        instance_exec(&callback)
      end
    end
  end
end
