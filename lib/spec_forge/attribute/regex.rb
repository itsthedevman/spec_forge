# frozen_string_literal: true

module SpecForge
  class Attribute
    class Regex < Attribute
      KEYWORD_REGEX = /^\/(?<content>[\s\S]+)\/(?<flags>[mnix\s]*)$/i

      attr_reader :value

      def initialize(input)
        super

        @value = parse_regex(input)
      end

      def resolve
        @value
      end

      private

      def parse_regex(input)
        match = input.match(KEYWORD_REGEX)
        captures = match.named_captures.symbolize_keys

        flags = parse_flags(captures[:flags])
        Regexp.new(captures[:content], flags)
      end

      # I would've used Regexp.new(string, string), but it raises when "n" is provided as a flag
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
