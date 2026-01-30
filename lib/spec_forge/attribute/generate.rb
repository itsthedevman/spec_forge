# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents an attribute that generates data structures dynamically.
    #
    # This class provides generation functions like `array` that can create
    # collections of arbitrary size with evaluated values. It's useful for
    # testing batch endpoints or generating large payloads.
    #
    # @example Generate an array of static values
    #   generate.array:
    #     size: 5
    #     value: "test"
    #
    # @example Generate an array with faker values
    #   generate.array:
    #     size: 100
    #     value: "{{ faker.string.alphanumeric }}"
    #
    # @example Generate an array with sequential indices
    #   generate.array:
    #     size: 3
    #     value: "user_{{ index }}"
    #   # Produces: ["user_0", "user_1", "user_2"]
    #
    # @example Combine faker with index
    #   generate.array:
    #     size: 10
    #     value: "{{ faker.internet.username }}_{{ index }}"
    #
    class Generate < Parameterized
      #
      # Regular expression pattern that matches attribute keywords with this prefix.
      # Used for identifying this attribute type during parsing.
      # Matches case-insensitively (generate., GENERATE., Generate., etc.)
      #
      # @return [Regexp]
      #
      KEYWORD_REGEX = /^generate\./i

      #
      # The available generation methods
      #
      # @return [Array<String>]
      #
      METHODS = %w[
        array
      ].freeze

      #
      # The generation function name (e.g., "array")
      #
      # @return [String]
      #
      attr_reader :function

      #
      # Creates a new generate attribute with the specified function and arguments
      #
      # @raise [Error::InvalidGenerateFunctionError] If the function is not supported
      #
      # @see Parameterized#initialize
      #
      def initialize(...)
        super

        @function = @input.sub(KEYWORD_REGEX, "")
        raise Error::InvalidGenerateFunctionError.new(input, METHODS) unless METHODS.include?(function)

        prepare_arguments
      end

      #
      # Returns the result of applying the generation function
      #
      # @return [Object] The generated value
      #
      def value
        case function
        when "array"
          generate_array
        end
      end

      private

      #
      # Generates an array of the specified size with evaluated values
      #
      # The special variable `index` (0-based) is available within `value` expressions
      # and will shadow any existing variable with the same name during generation.
      #
      # @return [Array] The generated array
      #
      # @private
      #
      def generate_array
        args = @arguments[:keyword]
        size = args[:size].resolve
        value_template = args[:value]
        variables = SpecForge::Forge.context.variables

        Array.new(size) do |index|
          variables[:index] = index
          value_template.value
        ensure
          variables.delete(:index)
        end
      end
    end
  end
end
