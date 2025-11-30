# frozen_string_literal: true

module SpecForge
  class Forge
    module Action
      class Debug
        def self.default
          lambda do
            puts <<~STRING

              Debug triggered for:
            STRING

            puts inspect
          end
        end

        def initialize(step)
          @step = step

          @callback = SpecForge.configuration.on_debug_proc
        end

        def run
          instance_exec(&@callback)
        end
      end
    end
  end
end
