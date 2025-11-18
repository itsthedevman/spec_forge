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
      summary "Set up your SpecForge project (creates folders and config files)"

      description <<~DESC
        Creates the SpecForge project structure.

        Sets up:
          • spec_forge/blueprints/ for test files
          • spec_forge/factories/ for test data (optional)
          • spec_forge/openapi/ for documentation config (optional)
          • forge_helper.rb for configuration
      DESC

      option "--skip-openapi", "Skip generating the \"openapi\" directory"
      option "--skip-factories", "Skip generating the \"factories\" directory"

      #
      # Creates the "spec_forge", "spec_forge/factories", and "spec_forge/blueprints" directories
      # Also creates the "spec_forge.rb" initialization file
      #
      def call
        initialize_forge
        initialize_openapi unless options.skip_openapi
      end

      private

      def initialize_forge
        base_path = SpecForge.forge_path
        actions.empty_directory(base_path.join("blueprints"))
        actions.empty_directory(base_path.join("factories")) unless options.skip_factories
        actions.template("forge_helper.rb.tt", base_path.join("forge_helper.rb"))
      end

      def initialize_openapi
        # spec_forge/openapi
        openapi_path = SpecForge.openapi_path
        actions.empty_directory(openapi_path)

        # spec_forge/openapi/config
        config_path = openapi_path.join("config")

        actions.empty_directory(config_path)
        actions.empty_directory(config_path.join("paths")) # openapi/config/paths
        actions.empty_directory(config_path.join("components")) # openapi/config/components

        # openapi/config/openapi.yml
        actions.template("openapi.yml.tt", config_path.join("openapi.yml"))
      end
    end
  end
end
