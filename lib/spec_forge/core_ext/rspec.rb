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
          # Updating these at this point fixes the re-run for some failures - it depends
          failed_examples.each do |example|
            metadata = example.metadata[:example_group]

            # I might've uncovered an inconsistency here
            # When multiple specs fail, it appears that the rerun_commands will use
            # :rerun_file_path from the example's metadata.
            # But when a single spec is ran and fails, it's using :location.
            example.metadata[:location] = metadata[:rerun_file_path]
            example.metadata[:line_number] = metadata[:line_number]
          end

          og_colorized_rerun_commands.gsub(/rspec/i, "spec_forge")
            .gsub(/\[[\d:]+\]/, "")
        end
      end
    end
  end
end
