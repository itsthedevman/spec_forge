# frozen_string_literal: true

module SpecForge
  class CLI
    class Init < Command
      command_name "init"
      syntax "init"
      summary "Initializes directory structure and configuration files"

      def call
        base_path = "spec_forge"
        actions.empty_directory "#{base_path}/factories"
        actions.empty_directory "#{base_path}/specs"

        actions.create_file(
          SpecForge.root.join(base_path, "config.yml"),
          SpecForge.config.to_config_yaml
        )
      end
    end
  end
end
