# frozen_string_literal: true

module SpecForge
  class Forge
    class Debug < Action
      def self.default
        lambda do
          puts <<~STRING

            Debug triggered for:
          STRING

          puts inspect
        end
      end

      def initialize
        super

        @callback = SpecForge.configuration.on_debug_proc
      end

      def run(forge)
        forge.display.action(:debug, "Debug breakpoint triggered", color: :orange)

        instance_exec(&@callback)
      end
    end
  end
end
