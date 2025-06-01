# frozen_string_literal: true

module SpecForge
  class CLI
    #
    # Command for initializing a new SpecForge project structure
    #
    # @example Creating a new SpecForge project
    #   spec_forge init
    #
    class Init < Command
      command_name "init"
      syntax "init"
      summary "Initializes directory structure and configuration files"

      option "--skip-docs", "Skip generating the \"docs\" directory"
      option "--skip-factories", "Skip generating the \"factories\" directory"

      #
      # Creates the "spec_forge", "spec_forge/factories", and "spec_forge/specs" directories
      # Also creates the "spec_forge.rb" initialization file
      #
      def call
        base_path = SpecForge.forge_path
        actions.empty_directory(base_path.join("specs"))
        actions.empty_directory(base_path.join("factories")) unless options.skip_factories

        actions.template("forge_helper.tt", base_path.join("forge_helper.rb"))

        unless options.skip_docs
          # spec_forge/openapi
          openapi_path = SpecForge.openapi_path
          actions.empty_directory(openapi_path)

          # spec_forge/openapi/config
          config_path = openapi_path.join("config")

          actions.empty_directory(config_path)
          actions.empty_directory(config_path.join("paths")) # openapi/config/paths
          actions.empty_directory(config_path.join("schemas")) # openapi/config/schemas

          # openapi/config/openapi.yml
          actions.template("openapi.tt", config_path.join("openapi.yml"))

          # spec_forge/openapi/generated
          generated_path = openapi_path.join("generated")
          actions.empty_directory(generated_path.join(".cache")) # openapi/generated/.cache
        end
      end
    end
  end
end
