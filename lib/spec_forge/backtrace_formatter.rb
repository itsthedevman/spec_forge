# frozen_string_literal: true

module SpecForge
  module BacktraceFormatter
    def self.format_backtrace(backtrace, example_metadata)
      backtrace = SpecForge.backtrace_cleaner.clean(backtrace)

      location = example_metadata[:example_group][:location]
      line_number = example_metadata[:example_group][:line_number]

      ["#{location}:#{line_number}"] + backtrace
    end
  end
end
