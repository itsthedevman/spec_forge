# frozen_string_literal: true

require_relative "cli/actions"
require_relative "cli/command"
require_relative "cli/docs"
require_relative "cli/init"
require_relative "cli/new"
require_relative "cli/run"
require_relative "cli/serve"

module SpecForge
  #
  # Command-line interface for SpecForge that provides the overall command structure
  # and entry point for the CLI functionality.
  #
  # @example Running a specific command
  #   # From command line: spec_forge init
  #
  class CLI
    include Commander::Methods

    #
    # @return [Array<SpecForge::CLI::Command>] All available commands
    #
    COMMANDS = [Docs, Init, New, Run, Serve].freeze

    #
    # Runs the CLI application, setting up program information and registering commands
    #
    def run
      program :name, "SpecForge"
      program :version, SpecForge::VERSION
      program :description, <<~DESC.strip
        Write expressive API tests in YAML with the power of RSpec matchers.

        Quick Start:
          spec_forge init              # Set up your project
          spec_forge new spec users    # Create your first test
          spec_forge run               # Execute tests
          spec_forge docs              # Generate API docs
          spec_forge serve             # Serve API docs locally
      DESC

      register_commands

      default_command :help

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
