# frozen_string_literal: true

module SpecForge
  class Attribute
    class Transform < Parameterized
      KEYWORD_REGEX = /^transform\./i

      TRANSFORM_METHODS = %w[
        join
      ].freeze

      attr_reader :function

      #
      # Represents any attribute that is a transform call
      #
      #   transform.<function>
      #
      def initialize(...)
        super

        # Remove prefix
        @function = @input.sub("transform.", "")

        raise InvalidTransformFunctionError, input unless TRANSFORM_METHODS.include?(function)

        prepare_arguments!
      end

      def value
        case function
        when "join"
          # Technically supports any attribute, but I ain't gonna test all them edge cases
          arguments[:positional].resolve.join
        end
      end
    end
  end
end
