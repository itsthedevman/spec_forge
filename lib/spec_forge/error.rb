# frozen_string_literal: true

module SpecForge
  class Error < StandardError; end

  class InvalidFakerClass < Error
    def initialize(input)
      super("Invalid Faker class \"#{input}\". Please check https://github.com/faker-ruby/faker#generators for available classes.")
    end
  end

  class InvalidFakerMethod < Error
    def initialize(input, klass)
      super("Undefined Faker method \"#{input}\" for \"#{klass}\". Please check https://github.com/faker-ruby/faker#generators for available methods.")
    end
  end
end
