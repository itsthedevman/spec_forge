# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents an attribute that transforms other attributes
    #
    # This class provides transformation functions like join that can be applied
    # to other attributes or values. It allows complex data manipulation without
    # writing Ruby code.
    #
    # @example Join transformation in YAML
    #   full_name:
    #     transform.join:
    #     - variables.first_name
    #     - " "
    #     - variables.last_name
    #
    class Transform < Parameterized
      #
      # Regular expression pattern that matches attribute keywords with this prefix
      # Used for identifying this attribute type during parsing
      #
      # @return [Regexp]
      #
      KEYWORD_REGEX = /^transform\./i

      #
      # The available transformation methods
      #
      # @return [Array<String>]
      #
      TRANSFORM_METHODS = %w[
        join
      ].freeze

      attr_reader :function

      #
      # Creates a new transform attribute with the specified function and arguments
      #
      def initialize(...)
        super

        # Remove prefix
        @function = @input.sub("transform.", "")

        raise Error::InvalidTransformFunctionError, input unless TRANSFORM_METHODS.include?(function)

        prepare_arguments!
      end

      #
      # Returns the result of applying the transformation function
      #
      # @return [Object] The transformed value
      #
      def value
        case function
        when "join"
          # Technically supports any attribute, but I ain't gonna test all them edge cases
          arguments[:positional].resolved.join
        end
      end
    end
  end
end
