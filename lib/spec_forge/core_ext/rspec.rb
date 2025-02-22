# frozen_string_literal: true

module RSpec
  module Core
    module Notifications
      #
      # I did attempt to do this without monkey patching
      # Getting around the `rspec` word was making it difficult
      #
      class SummaryNotification
        # Customizes RSpec's failure output to:
        # 1. Use 'spec_forge' instead of 'rspec' for rerun commands
        # 2. Remove line numbers since SpecForge uses dynamic spec generation
        alias_method :og_colorized_rerun_commands, :colorized_rerun_commands

        def colorized_rerun_commands(colorizer)
          og_colorized_rerun_commands.gsub(/rspec/i, "spec_forge")
            .gsub(/\[[\d:]+\]/, "")
        end
      end
    end
  end
end
