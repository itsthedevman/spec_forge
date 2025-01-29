# frozen_string_literal: true

require_relative "attribute/parameterized"

require_relative "attribute/faker"
require_relative "attribute/literal"
require_relative "attribute/transform"

module SpecForge
  class Attribute
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
      when Hash
        from_hash(value)
      when Array
        Literal.new(value.map { |v| Attribute.from(v) })
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
      if string.match?(/^faker\./i)
        Faker.new(string)
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

      if has_macro.call(hash, /^transform\./i)
        Transform.from_hash(hash)
      elsif has_macro.call(hash, /^faker\./i)
        Faker.from_hash(hash)
      else
        hash = hash.transform_values { |v| Attribute.from(v) }
        Literal.new(hash)
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
    # Returns the fully evaluated result, recursively processing any nested attributes
    #
    # @return [Object] The evaluated result
    #
    # @example Simple literal
    #   attr = Attribute::Literal.new("hello")
    #   attr.result # => "hello"
    #
    # @example Nested array with faker
    #   attr = Attribute::Literal.new(["faker.number.positive", ["faker.name.first_name"]])
    #   attr.result # => [42, ["Jane"]]
    #
    def result
      converted_value = value
      case converted_value
      when Array
        converted_value.map(&:values)
      when Hash
        converted_value.transform_values(&:values)
      else
        converted_value
      end
    end

    #
    # Wraps the call to #result in a proc. Used with FactoryBot
    #
    # @return [Proc]
    #
    def to_proc
      this = self # kek - what are we, javascript?
      -> { this.result }
    end
  end
end
