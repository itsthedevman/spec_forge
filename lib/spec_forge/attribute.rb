# frozen_string_literal: true

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
      when Attribute, ResolvableArray, ResolvableHash, ResolvableStruct
        value
      when ArrayLike
        array = value.map { |v| Attribute.from(v) }
        ResolvableArray.new(array)
      when Struct, Data, OpenStruct
        ResolvableStruct.new(value)
      else
        Literal.new(value)
      end
    end

    #
    # Creates an Attribute instance from a string
    #
    # @param string [String] The input string
    #
    # @return [Attribute]
    #
    # @private
    #
    def self.from_string(string)
      klass =
        case string
        when Template::REGEX
          Template
        when Factory::KEYWORD_REGEX
          Factory
        when Faker::KEYWORD_REGEX
          Faker
        when Matcher::KEYWORD_REGEX
          Matcher
        when Regex::KEYWORD_REGEX
          Regex
        else
          Literal
        end

      klass.new(string)
    end

    #
    # Creates an Attribute instance from a hash
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
        ResolvableHash.new(hash)
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
    #   faker_attr.resolved # => "Jane" (result is cached in @resolved)
    #   faker_attr.resolved # => "Jane" (returns same cached value)
    #
    def resolved
      @resolved ||= resolve
    end

    #
    # Performs recursive resolution of the attribute's value.
    # Handles nested arrays and hashes by recursively resolving their elements.
    #
    # Unlike #resolved, this method doesn't cache results and can be used
    # when fresh resolution is needed each time.
    #
    # @return [Object] The recursively resolved value without caching
    #
    # @example
    #   hash_attr = Attribute::ResolvableHash.new({name: Attribute::Faker.new("faker.name.name")})
    #   hash_attr.resolve # => {name: "John Smith"}
    #   hash_attr.resolve # => {name: "Jane Doe"} (different value on each call)
    #
    def resolve
      case value
      when ArrayLike
        value.map(&resolved_proc)
      when HashLike
        value.transform_values(&resolved_proc)
      else
        value
      end
    end

    def resolve_as_matcher
      methods = Attribute::Matcher::MATCHER_METHODS

      case resolved
      when Array, ArrayLike
        resolved_array = resolved.map(&resolve_as_matcher_proc)

        if resolved_array.size > 0
          resolved_array
        else
          methods.eq([])
        end
      when Hash, HashLike
        resolved_hash = resolved.transform_values(&resolve_as_matcher_proc).stringify_keys

        if resolved_hash.size > 0
          resolved_hash
        else
          methods.eq({})
        end
      when Attribute::Matcher, Regexp
        methods.match(resolved)
      when RSpec::Matchers::BuiltIn::BaseMatcher,
          RSpec::Matchers::DSL::Matcher,
          Class
        resolved # Pass through
      else
        methods.eq(resolved)
      end
    end
  end
end
