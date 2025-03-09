# frozen_string_literal: true

# Need to be first
require_relative "attribute/parameterized"
require_relative "attribute/chainable"
require_relative "attribute/resolvable"

module SpecForge
  #
  # Base class for all attribute types in SpecForge.
  # Attributes represent values that can be transformed, resolved, or have special meaning
  # in the context of specs and expectations.
  #
  # The Attribute system handles dynamic data generation, variable references,
  # matchers, transformations and other special values in YAML specs.
  #
  # @example Basic usage in YAML
  #   username: faker.internet.username    # A dynamic faker attribute
  #   email: /\w+@\w+\.\w+/                # A regex attribute
  #   status: kind_of.integer              # A matcher attribute
  #   user_id: variables.user.id           # A variable reference
  #
  class Attribute
    include Resolvable

    #
    # Binds variables to Attribute objects
    #
    # @param input [Array, Hash, Attribute] The input to loop through or bind to
    # @param variables [Hash] Any variables to available to assign
    #
    # @return [Array, Hash, Attribute] The input with bounded variables
    #
    def self.bind_variables(input, variables = {})
      case input
      when ArrayLike
        input.each { |v| v.bind_variables(variables) }
      when HashLike
        input.each_value { |v| v.bind_variables(variables) }
      when Attribute
        input.bind_variables(variables)
      end

      input
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
      when HashLike
        from_hash(value)
      when Attribute
        value
      when ArrayLike
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
      when Factory::KEYWORD_REGEX
        Factory.new(string)
      when Regex::KEYWORD_REGEX
        Regex.new(string)
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
      elsif has_macro.call(hash, Factory::KEYWORD_REGEX)
        Factory.from_hash(hash)
      else
        hash = hash.transform_values { |v| Attribute.from(v) }
        Attribute::ResolvableHash.new(hash)
      end
    end

    #
    # The original input value
    #
    # @return [Object]
    #
    attr_reader :input

    #
    # Creates a new attribute
    #
    # @param input [Object] The original input value
    #
    def initialize(input)
      @input = input
    end

    #
    # Returns the processed value of this attribute.
    # Recursively calls #value on underlying attributes, but does NOT resolve
    # all nested structures completely.
    #
    # This returns an intermediate representation - for fully resolved values, use #resolve instead.
    #
    # @return [Object] The processed value of this attribute
    #
    # @raise [RuntimeError] if not implemented by subclass
    #
    # @example
    #   variable_attr = Attribute::Variable.new("variables.user")
    #   variable_attr.value # => User instance, but any attributes of User remain
    #   as Attribute objects
    #
    def value
      raise "not implemented"
    end

    #
    # Returns the fully evaluated result with complete recursive resolution.
    # Calls #value internally and then resolves all nested attributes, caching the result.
    #
    # Use this when you need the final, fully-resolved value with all nested attributes
    # fully evaluated to their primitive values.
    #
    # @return [Object] The completely resolved value with cached results
    #
    # @example
    #   faker_attr = Attribute::Faker.new("faker.name.first_name")
    #   faker_attr.resolve # => "Jane" (result is cached in @resolved)
    #   faker_attr.resolve # => "Jane" (returns same cached value)
    #
    def resolve
      @resolved ||= resolve_value
    end

    #
    # Similar to #resolve but doesn't cache the result, allowing for re-resolution.
    # Recursively calls #resolve on all nested attributes without storing results.
    #
    # Use this when you need to ensure fresh values each time, particularly with
    # factories or other attributes that should generate new values on each call.
    #
    # @return [Object] The completely resolved value without caching
    #
    # @example
    #   factory_attr = Attribute::Factory.new("factories.user")
    #   factory_attr.resolve_value # => User#1 (a new user)
    #   factory_attr.resolve_value # => User#2 (another new user)
    #
    def resolve_value
      __resolve(value)
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

    #
    # Used to bind variables to self or any sub attributes
    #
    # @param variables [Hash] A hash of variable attributes
    #
    def bind_variables(variables)
    end

    protected

    #
    # Helper method to recursively resolve nested values
    #
    # @param value [Object] The value to resolve
    #
    # @return [Object] The resolved value with any nested attributes resolved
    #
    # @private
    #
    def __resolve(value)
      case value
      when ArrayLike
        value.map(&resolvable_proc)
      when HashLike
        value.transform_values(&resolvable_proc)
      else
        value
      end
    end
  end
end

# Order doesn't matter
require_relative "attribute/factory"
require_relative "attribute/faker"
require_relative "attribute/global"
require_relative "attribute/literal"
require_relative "attribute/matcher"
require_relative "attribute/regex"
require_relative "attribute/resolvable_array"
require_relative "attribute/resolvable_hash"
require_relative "attribute/transform"
require_relative "attribute/variable"
