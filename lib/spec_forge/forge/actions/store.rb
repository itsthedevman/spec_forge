# frozen_string_literal: true

module SpecForge
  class Forge
    #
    # Action for the `store:` step attribute
    #
    # Resolves attribute values and stores them as variables for use by
    # subsequent steps. Can store literal values or extract values from
    # the response using template syntax.
    #
    class Store < Action
      #
      # Stores all configured values in the forge's variables
      #
      # @param forge [Forge] The forge instance
      #
      # @return [void]
      #
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
