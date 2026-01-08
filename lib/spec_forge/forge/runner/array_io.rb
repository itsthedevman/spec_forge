# frozen_string_literal: true

module SpecForge
  class Forge
    class Runner
      #
      # IO-like object that stores writes in an array instead of a string buffer
      #
      # Used with RSpec's JSON formatter to capture each JSON output as a separate
      # entry rather than concatenating them into one long string.
      #
      class ArrayIO
        #
        # All entries written to this IO
        #
        # @return [Array<String>]
        #
        attr_reader :entries

        # @return [Boolean] Whether the IO has been closed
        attr_predicate :closed

        def initialize
          @entries = []
        end

        #
        # Writes a string as a new entry
        #
        # @param string [String] The string to write
        #
        # @return [void]
        #
        def write(string)
          @entries << string
        end

        #
        # Writes strings with newlines appended
        #
        # @param strings [Array<String>] Strings to write
        #
        # @return [void]
        #
        def puts(*strings)
          strings.each { |string| write(string + "\n") }
        end

        #
        # Appends a string (alias for write)
        #
        # @param string [String] The string to append
        #
        # @return [void]
        #
        def <<(string)
          write(string)
        end

        #
        # Clears all entries
        #
        # @return [Integer] Always returns 0
        #
        def flush
          @entries.clear
          0
        end

        #
        # Marks the IO as closed
        #
        # @return [void]
        #
        def close
          @closed = true
        end
      end
    end
  end
end
