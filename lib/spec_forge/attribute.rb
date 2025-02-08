# frozen_string_literal: true

# Need to be first
require_relative "attribute/parameterized"
require_relative "attribute/chainable"

# Doesn't matter
require_relative "attribute/factory"
require_relative "attribute/faker"
require_relative "attribute/literal"
require_relative "attribute/matcher"
require_relative "attribute/resolvable_array"
require_relative "attribute/resolvable_hash"
require_relative "attribute/transform"
require_relative "attribute/variable"

module SpecForge
  class Attribute
    #
    # Transforms a hash's values into Attributes and updates any Attribute::Variable's values
    #
    # @param hash [Hash] Hash whose values need to be transformed into Attributes
    #
    # @param variables [Array] List of variables to update the Attribute values with (default: [])
    #
    # @return [Hash] Hash with values transformed into Attributes and updated with variables
    #
    def self.update_hash_values(hash, variables = {})
      hash.each_value { |v| Variable.update_value!(v, variables) }
    end

    #
    # Creates an Attribute instance based on the input value's type and content.
    # Recursively converts Array and Hash
    #
    # @param value [Object] The input value to convert into an Attribute
    #
    # @return [Attribute] A new Attribute instance of the appropriate subclass
    #
    def self.from(value)
      case value
      when String
        from_string(value)
      when Hash, ResolvableHash
        from_hash(value)
      when Attribute
        value
      when Array, ResolvableArray
        array = value.map { |v| Attribute.from(v) }
        Attribute::ResolvableArray.new(array)
      else
        Literal.new(value)
      end
    end

    #
    # Creates an Attribute instance from a string, handling any macros
    #
    # @param string [String] The input string
    #
    # @return [Attribute]
    #
    # @private
    #
    def self.from_string(string)
      case string
      when Faker::KEYWORD_REGEX
        Faker.new(string)
      when Variable::KEYWORD_REGEX
        Variable.new(string)
      when Matcher::KEYWORD_REGEX
        Matcher.new(string)
      else
        Literal.new(string)
      end
    end

    #
    # Creates an Attribute instance from a hash, handling any macros
    #
    # @param hash [Hash] The input hash
    #
    # @return [Attribute]
    #
    # @private
    #
    def self.from_hash(hash)
      # Determine if the hash is an expanded macro call
      has_macro = ->(h, regex) { h.any? { |k, _| k.match?(regex) } }

      if has_macro.call(hash, Transform::KEYWORD_REGEX)
        Transform.from_hash(hash)
      elsif has_macro.call(hash, Faker::KEYWORD_REGEX)
        Faker.from_hash(hash)
      elsif has_macro.call(hash, Matcher::KEYWORD_REGEX)
        Matcher.from_hash(hash)
      else
        hash = hash.transform_values { |v| Attribute.from(v) }
        Attribute::ResolvableHash.new(hash)
      end
    end

    attr_reader :input

    #
    # @param input [Object] Anything
    #
    def initialize(input)
      @input = input
    end

    #
    # Returns the processed value of the input
    #
    # For literals, this is the input itself.
    # For generated values (Faker, Transform), this is the result of their operations.
    #
    # @return [Object] The processed value of this attribute
    #
    # @raise [RuntimeError] if not implemented by subclass
    #
    def value
      raise "not implemented"
    end

    #
    # Returns the fully evaluated result, recursively resolving any nested attributes
    # Note: This method can only be called once to ensure data is correct across the board
    # You can still call #value if you need a new value
    #
    # @return [Object] The resolved value
    #
    # @example Simple literal
    #   attr = Attribute::Literal.new("hello")
    #   attr.resolve # => "hello"
    #
    # @example Nested array with faker
    #   attr = Attribute::Literal.new(["faker.number.positive", ["faker.name.first_name"]])
    #   attr.resolve # => [42, ["Jane"]]
    #
    def resolve
      # Past test for the variable
      @resolved ||= __resolve(value)
    end

    #
    # Wraps the call to #resolve in a proc. Used with FactoryBot
    #
    # @return [Proc]
    #
    def to_proc
      this = self # kek - what are we, javascript?
      -> { this.resolve }
    end

    #
    # Compares this attributes input to other
    #
    # @param other [Object, Attribute] If another Attribute, the input will be compared
    #
    # @return [Boolean]
    #
    def ==(other)
      other =
        if other.is_a?(Attribute)
          other.input
        else
          other
        end

      input == other
    end

    protected

    def __resolve(value)
      case value
      when Array, ResolvableArray
        value.map(&:resolve)
      when Hash, ResolvableHash
        value.transform_values(&:resolve)
      else
        value
      end
    end
  end
end
