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

      def run(_forge)
        instance_exec(&@callback)
      end
    end
  end
end
