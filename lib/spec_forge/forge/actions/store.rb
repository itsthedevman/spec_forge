# frozen_string_literal: true

module SpecForge
  class Forge
    class Store < Action
      def run(forge)
        step.store.each do |name, value|
          event = forge.variables.key?(name) ? "Update" : "Store"

          forge.display.action(:store, "#{event} #{name.in_quotes}", color: :bright_cyan)

          forge.variables[name] = value.resolved
        end
      end
    end
  end
end
