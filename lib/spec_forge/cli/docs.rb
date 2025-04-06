# frozen_string_literal: true

module SpecForge
  class CLI
    class Docs < Command
      command_name "docs"
      syntax "docs <action>"
      summary "TODO"

      def call
        case (action = arguments.first)
        when "generate"
          Documentation.generate
        when "serve"
          nil
        else
          raise ArgumentError, "Unexpected action #{action&.in_quotes}. Expected \"generate\" or \"serve\""
        end
      end
    end
  end
end
