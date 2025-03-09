# frozen_string_literal: true

module SpecForge
  #
  # Used internally by RSpec to format backtraces for test failures
  # Customizes error output to make it more readable and useful for SpecForge
  #
  module BacktraceFormatter
    #
    # Returns the RSpec backtrace formatter instance
    # Lazily initializes the formatter on first access
    #
    # @return [RSpec::Core::BacktraceFormatter] The backtrace formatter
    #
    def self.formatter
      @formatter ||= RSpec::Core::BacktraceFormatter.new
    end

    #
    # Formats a single backtrace line
    # Delegates to the RSpec formatter
    #
    # @param line [String] The backtrace line to format
    #
    # @return [String] The formatted backtrace line
    #
    def self.backtrace_line(line)
      formatter.backtrace_line(line)
    end

    #
    # Formats a complete backtrace for an example
    # Adds the YAML location to the front of the backtrace for better context
    #
    # @param backtrace [Array<String>] The raw backtrace lines
    # @param example_metadata [Hash] Metadata about the failing example
    #
    # @return [Array<String>] The formatted backtrace with YAML location first
    #
    def self.format_backtrace(backtrace, example_metadata)
      backtrace = SpecForge.backtrace_cleaner.clean(backtrace)

      location = example_metadata[:example_group][:location]
      line_number = example_metadata[:example_group][:line_number]

      # Add the yaml location to the front so it's the first thing people see
      ["#{location}:#{line_number}"] + backtrace
    end
  end
end
