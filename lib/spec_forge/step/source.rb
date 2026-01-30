# frozen_string_literal: true

module SpecForge
  class Step
    #
    # Represents the source location of a step in a blueprint file
    #
    # Tracks which file and line number a step came from, which is
    # useful for error messages and debugging output.
    #
    class Source < Data.define(:file_name, :line_number)
      #
      # Returns a formatted string representation of the source location
      #
      # @return [String] Format: "file_name:line_number"
      #
      def to_s
        "#{file_name}:#{line_number}"
      end
    end
  end
end
