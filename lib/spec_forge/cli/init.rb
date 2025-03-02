# frozen_string_literal: true

module SpecForge
  class CLI
    class Init < Command
      command_name "init"
      syntax "init"
      summary "Initializes directory structure and configuration files"

      def call
        base_path = SpecForge.forge_path
        actions.empty_directory "#{base_path}/factories"
        actions.empty_directory "#{base_path}/specs"

        actions.template(
          "forge_helper.tt",
          SpecForge.root.join(base_path, "forge_helper.rb")
        )
      end
    end
  end
end
