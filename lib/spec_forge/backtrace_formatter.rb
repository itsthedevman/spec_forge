# frozen_string_literal: true

module SpecForge
  #
  # Used internally by RSpec
  # This class handles formatting backtraces, hence the name ;)
  #
  module BacktraceFormatter
    def self.formatter
      @formatter ||= RSpec::Core::BacktraceFormatter.new
    end

    def self.backtrace_line(line)
      formatter.backtrace_line(line)
    end

    def self.format_backtrace(backtrace, example_metadata)
      backtrace = SpecForge.backtrace_cleaner.clean(backtrace)

      location = example_metadata[:example_group][:location]
      line_number = example_metadata[:example_group][:line_number]

      # Add the yaml location to the front so it's the first thing people see
      ["#{location}:#{line_number}"] + backtrace
    end
  end
end
