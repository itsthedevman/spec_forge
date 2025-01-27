# frozen_string_literal: true

module SpecForge
  class CLI
    class Run < Command
      command_name "run"
      syntax "run"
      summary "Runs all specs"

      option "-n", "--no-docs", "Do not generate OpenAPI documentation on completion"

      def call
      end

      private
    end
  end
end
