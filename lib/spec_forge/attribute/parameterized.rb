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
      # @param options [Hash] Additional options to pass to the attribute (e.g., context)
      #
      # @return [Parameterized] A new parameterized attribute instance
      #
      def self.from_hash(hash, **options)
        metadata = hash.first

        input = metadata.first
        arguments = metadata.second

        case arguments
        when Array
          new(input, positional: arguments, **options)
        when Hash
          new(input, keyword: arguments, **options)
        else
          # Single value
          new(input, positional: [arguments], **options)
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
      # @param options [Hash] Options including positional and keyword arguments
      # @option options [Array] :positional Positional arguments
      # @option options [Hash] :keyword Keyword arguments
      #
      def initialize(...)
        super

        @input = @input.to_s.downcase

        @arguments = {
          positional: @options[:positional] || [],
          keyword: @options[:keyword] || {}
        }

        @options.clear # No need to store a duplicate
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
