# frozen_string_literal: true

return if defined?(SPEC_FORGE_INTERNAL_TESTING)

#
# RSpec's core testing framework module
# Provides the fundamental structure and functionality for RSpec tests
#
module RSpec
  #
  # Core implementation details and extensions for RSpec
  # Contains the fundamental building blocks of the RSpec testing framework
  #
  module Core
    #
    # Handles notifications and reporting for RSpec test runs
    # Manages how test results and metadata are processed and communicated
    #
    module Notifications
      #
      # A monkey patch of an internal RSpec class to allow SpecForge to replace parts of
      # RSpec's reporting output in order to provide useful feedback to the user.
      # This replaces "rspec" in commands with "spec_forge", removes any line numbers, and
      # ensures that failures properly report the YAML file that it occurred in.
      #
      class SummaryNotification
        #
        # Create an alias to RSpec original colorized_rerun_commands so it can be called at a
        # later point.
        #
        alias_method :og_colorized_rerun_commands, :colorized_rerun_commands

        # Customizes RSpec's failure output to:
        # 1. Use 'spec_forge' instead of 'rspec' for rerun commands
        # 2. Remove line numbers since SpecForge uses dynamic spec generation
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
