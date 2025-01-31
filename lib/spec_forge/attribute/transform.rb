# frozen_string_literal: true

module SpecForge
  class Attribute
    class Transform < Parameterized
      KEYWORD_REGEX = /^transform\./i

      attr_reader :transform_method

      def initialize(...)
        super

        # Remove prefix
        function = @input.sub("transform.", "")

        @transform_method =
          case function
          when "join"
            lambda do
              # Technically supports any attribute, but I ain't gonna test all them edge cases
              array = @arguments[:positional].map { |i| Attribute.from(i).value }
              array.join
            end
          else
            raise InvalidTransformFunctionError, @input
          end
      end

      def value
        @transform_method.call
      end
    end
  end
end
