# frozen_string_literal: true

module SpecForge
  class Forge
    class Store < Action
      def run(forge)
        step.store.each do |name, value|
          event = forge.variables.key?(name) ? "Updated" : "Stored"

          forge.display.action(:store, "#{event}: #{name.in_quotes}", color: :bright_cyan)
          forge.variables[name] = value
        end
      end
    end
  end
end
