# frozen_string_literal: true

module SpecForge
  class Error < StandardError; end

  class InvalidFakerClass < Error
    def initialize(input)
      super(
        "Invalid Faker class \"#{input}\". Please check https://github.com/faker-ruby/faker#generators for available classes."
      )
    end
  end

  class InvalidFakerMethod < Error
    def initialize(input, klass)
      spell_checker = DidYouMean::SpellChecker.new(dictionary: klass.public_methods)
      corrections = spell_checker.correct(input)

      super(<<~STRING
        "Undefined Faker method "#{input}" for "#{klass}". #{DidYouMean::Formatter.message_for(corrections)}

        If not, please check https://github.com/faker-ruby/faker#generators for available methods."
      STRING
      )
    end
  end
end
