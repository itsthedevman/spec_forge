# frozen_string_literal: true

module SpecForge
  class CLI
    class Init < Command
      command_name "init"
      syntax "init"
      summary "Initializes directory structure and configuration files"

      def call
        base_path = SpecForge.forge
        actions.empty_directory "#{base_path}/factories"
        actions.empty_directory "#{base_path}/specs"

        # actions.template(
        #   "config.tt",
        #   SpecForge.root.join(base_path, "config.yml"),
        #   context: binding
        # )
      end
    end
  end
end
