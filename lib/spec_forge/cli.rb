# frozen_string_literal: true

require_relative "cli/actions"
require_relative "cli/command"
require_relative "cli/init"
require_relative "cli/new"
require_relative "cli/run"

module SpecForge
  #
  # Command-line interface for SpecForge that provides the overall command structure
  # and entry point for the CLI functionality.
  #
  # @example Running the default command
  #   SpecForge::CLI.new.run
  #
  # @example Running a specific command
  #   # From command line: spec_forge init
  #
  class CLI
    include Commander::Methods

    COMMANDS = [Init, New, Run]

    #
    # Runs the CLI application, setting up program information and registering commands
    #
    def run
      program :name, "SpecForge"
      program :version, SpecForge::VERSION
      program :description, "Write expressive API tests in YAML with the power of RSpec matchers"

      register_commands

      default_command :run

      run!
    end

    #
    # Registers the command classes with Commander
    #
    # @private
    #
    def register_commands
      COMMANDS.each do |command_class|
        command_class.register(self)
      end
    end
  end
end
