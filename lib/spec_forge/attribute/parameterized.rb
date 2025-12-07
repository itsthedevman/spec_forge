# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Base class for attributes that support positional and keyword arguments
    #
    # This class provides the foundation for attributes that need to accept
    # arguments, such as Faker, Matcher, and Factory. It handles both positional
    # (array-style) and keyword (hash-style) arguments.
    #
    # @example With keyword arguments in YAML
    #   example:
    #     keyword:
    #       arg1: value1
    #       arg2: value2
    #
    # @example With positional arguments in YAML
    #   example:
    #     keyword:
    #     - arg1
    #     - arg2
    #
    class Parameterized < Attribute
      #
      # Creates a new attribute instance from a hash representation
      #
      # @param hash [Hash] A hash containing the attribute name and arguments
      #
      # @return [Parameterized] A new parameterized attribute instance
      #
      def self.from_hash(hash)
        metadata = hash.first

        input = metadata.first
        arguments = metadata.second

        case arguments
        when ArrayLike
          new(input, arguments)
        when HashLike
          # Offset for positional arguments. No support for both at this time
          new(input, [], arguments)
        else
          # Single value
          new(input, [arguments])
        end
      end

      #
      # A hash containing both positional and keyword arguments for this attribute
      # The hash has two keys: :positional (Array) and :keyword (Hash)
      #
      # @return [Hash{Symbol => Object}] The arguments hash with structure:
      #   {
      #     positional: Array - Contains positional arguments in order
      #     keyword: Hash - Contains keyword arguments as key-value pairs
      #   }
      #
      attr_reader :arguments

      #
      # Creates a new parameterized attribute with the specified arguments
      #
      # @param input [String, Symbol] The key that contains these arguments
      # @param positional [Array] Any positional arguments
      # @param keyword [Hash] Any keyword arguments
      #
      def initialize(input, positional = [], keyword = {})
        super(input.to_s.downcase)

        @arguments = {positional:, keyword:}
      end

      protected

      #
      # Converts the arguments into Attributes
      #
      # @note This needs to be called by the inheriting class.
      #   This is to allow inheriting classes to normalize their arguments before
      #   they are converted to Attributes
      #
      # @private
      #
      def prepare_arguments
        @arguments = Attribute.from(arguments)
      end
    end
  end
end
