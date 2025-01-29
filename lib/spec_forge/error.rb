# frozen_string_literal: true

module SpecForge
  class Error < StandardError; end

  class InvalidFakerClass < Error
    def initialize(input)
      dictionary = Faker::Base.descendants.map { |c| c.to_s.downcase.gsub!("::", ".") }
      spell_checker = DidYouMean::SpellChecker.new(dictionary:)
      corrections = spell_checker.correct(input)

      super(<<~STRING.chomp
        Undefined Faker class "#{input}". #{DidYouMean::Formatter.message_for(corrections)}

        For available classes, please check https://github.com/faker-ruby/faker#generators.
      STRING
      )
    end
  end

  class InvalidFakerMethod < Error
    def initialize(input, klass)
      spell_checker = DidYouMean::SpellChecker.new(dictionary: klass.public_methods)
      corrections = spell_checker.correct(input)

      super(<<~STRING.chomp
        Undefined Faker method "#{input}" for "#{klass}". #{DidYouMean::Formatter.message_for(corrections)}

        For available methods for this class, please check https://github.com/faker-ruby/faker#generators.
      STRING
      )
    end
  end

  class InvalidTransformFunction < Error
    def initialize(input)
      # TODO: Update link to docs
      super(<<~STRING.chomp
        Undefined transform function "#{input}".

        For available functions, please check https://github.com/itsthedevman/spec_forge.
      STRING
      )
    end
  end
end
