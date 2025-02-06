# frozen_string_literal: true

require_relative "cli/actions"
require_relative "cli/command"
require_relative "cli/init"
require_relative "cli/new"
require_relative "cli/run"

module SpecForge
  class CLI
    include Commander::Methods

    COMMANDS = [Init, New, Run]

    def run
      program :name, "SpecForge"
      program :version, SpecForge::VERSION
      program :description, "Write expressive API tests in YAML with the power of RSpec matchers"

      register_commands

      default_command :run

      run!
    end

    def register_commands
      COMMANDS.each do |command_class|
        command_class.register(self)
      end
    end
  end
end
