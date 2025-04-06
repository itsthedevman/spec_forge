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

        unless options.skip_docs
          actions.empty_directory(base_path.join("docs"))
          actions.empty_directory(base_path.join("docs", "schemas"))

          actions.template("docs_config.tt", base_path.join("docs", "config.yml"))
        end

        actions.template("forge_helper.tt", base_path.join("forge_helper.rb"))
      end
    end
  end
end
