# frozen_string_literal: true

require_relative "cli/actions"
require_relative "cli/command"
require_relative "cli/init"

module SpecForge
  class CLI
    include Commander::Methods

    COMMANDS = [Init]

    def run
      program :name, "SpecForge"
      program :version, SpecForge::VERSION
      program :description, "SpecForge is a config-driven API testing framework that generates OpenAPI documentation from your test suite."

      register_commands

      default_command :help

      run!
    end

    def register_commands
      COMMANDS.each do |command_class|
        command_class.register(self)
      end
    end
  end
end
