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
      program :description, "A doo daa"

      register_commands

      run!
    end

    def register_commands
      COMMANDS.each do |command_class|
        command_class.register(self)
      end
    end
  end
end
