# frozen_string_literal: true

require_relative "attribute/parameterized"

require_relative "attribute/faker"
require_relative "attribute/literal"
require_relative "attribute/transform"

module SpecForge
  class Attribute
    def self.from(value)
      case value
      when String
        from_string(value)
      when Hash
        from_hash(value)
      else
        Literal.new(value)
      end
    end

    def self.from_string(string)
      if string.match?(/^faker\./i)
        Faker.new(string)
      else
        Literal.new(string)
      end
    end

    def self.from_hash(hash)
      # Determine if the hash is an expanded macro call
      has_macro = ->(h, regex) { h.any? { |k, _| k.match?(regex) } }

      if has_macro.call(hash, /^transform\./i)
        Transform.from_hash(hash)
      elsif has_macro.call(hash, /^faker\./i)
        Faker.from_hash(hash)
      else
        Literal.new(hash)
      end
    end

    attr_reader :input

    def initialize(input)
      @input = input
    end

    # This needs to be implemented, even though @input already exists
    def value
      raise "not implemented"
    end

    def to_proc
      this = self # kek - what are we, javascript?
      -> { this.value }
    end
  end
end
