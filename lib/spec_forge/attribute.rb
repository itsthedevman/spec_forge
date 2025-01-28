# frozen_string_literal: true

require_relative "attribute/faker"
require_relative "attribute/literal"

module SpecForge
  class Attribute
    def self.from(value)
      case value
      when String
        case value
        when /^faker\./i
          Faker.new(value)
        # when /^factory\./i
        # when /^variables\./i
        # when /^transform\./i
        else
          Literal.new(value)
        end
      when Hash
        # TODO
      else
        Literal.new(value)
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
