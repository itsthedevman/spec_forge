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

        attr_predicate :closed

        def initialize
          @entries = []
        end

        def write(string)
          @entries << string
        end

        def puts(*strings)
          strings.each { |string| write(string + "\n") }
        end

        def <<(string)
          write(string)
        end

        def flush
          @entries.clear
          0
        end

        def close
          @closed = true
        end
      end
    end
  end
end
