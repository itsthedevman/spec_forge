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

      #
      # Creates the "spec_forge", "spec_forge/factories", and "spec_forge/specs" directories
      # Also creates the "spec_forge.rb" initialization file
      #
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
