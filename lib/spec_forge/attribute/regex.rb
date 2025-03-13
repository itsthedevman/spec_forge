# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents a regular expression attribute using Ruby's Regexp class.
    # This class handles the parsing of regex strings from YAML into actual Regexp objects,
    # including support for standard regex flags (m, n, i, x).
    #
    # @example Basic usage in YAML
    #   matcher: /pattern/i     # Case-insensitive matching
    #   email: /@/              # Simple pattern matching
    #   slug: /^[a-z0-9-]+$/    # Pattern with start/end anchors
    #
    # @example With flags
    #   description: /hello world/i   # Case-insensitive match using 'i' flag
    #   text_block: /^hello\s+\w+/m   # Multi-line match using 'm' flag
    #   mixed: /complex pattern/imx   # Multiple flags: case-insensitive, multi-line, extended mode
    #
    class Regex < Attribute
      #
      # Regular expression pattern that matches attribute keywords with this prefix
      # Used for identifying this attribute type during parsing
      #
      # @return [Regexp]
      #
      KEYWORD_REGEX = /^\/(?<content>[\s\S]+)\/(?<flags>[mnix\s]*)$/i

      #
      # The parsed Regexp object
      #
      # @return [Regexp]
      #
      attr_reader :value

      alias_method :resolved, :value
      alias_method :resolve, :value

      #
      # Creates a new regex attribute by parsing the input string
      #
      # @param input [String] The regular expression pattern as a string
      #
      def initialize(input)
        super

        @value = parse_regex(input)
      end

      private

      #
      # Parses a regex string into a Regexp object
      #
      # @param input [String] The string representation of the regex (e.g., "/pattern/i")
      #
      # @return [Regexp] The compiled regular expression
      #
      # @private
      #
      def parse_regex(input)
        match = input.match(KEYWORD_REGEX)
        captures = match.named_captures.symbolize_keys

        flags = parse_flags(captures[:flags])
        Regexp.new(captures[:content], flags)
      end

      #
      # Parses regex flags from a string into Regexp option bits
      # Supports i (case insensitive), m (multiline), x (extended), and n (no encoding)
      #
      # @param flags [String] A string containing the flags (e.g., "imx")
      #
      # @return [Integer] The combined flag options as a bitmask
      #
      # @raise [ArgumentError] If an unknown regex flag is provided
      #
      # @private
      #
      def parse_flags(flags)
        return 0 if flags.blank?

        flags.strip.chars.reduce(0) do |options, flag|
          case flag
          when "i"
            options | Regexp::IGNORECASE
          when "m"
            options | Regexp::MULTILINE
          when "x"
            options | Regexp::EXTENDED
          when "n"
            options | Regexp::NOENCODING
          else
            raise ArgumentError, "unknown regexp option: #{flag}"
          end
        end
      end
    end
  end
end
