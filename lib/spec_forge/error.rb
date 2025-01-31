# frozen_string_literal: true

module SpecForge
  class Error < StandardError; end

  class InvalidFakerClassError < Error
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

  class InvalidFakerMethodError < Error
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

  class InvalidTransformFunctionError < Error
    def initialize(input)
      # TODO: Update link to docs
      super(<<~STRING.chomp
        Undefined transform function "#{input}".

        For available functions, please check https://github.com/itsthedevman/spec_forge.
      STRING
      )
    end
  end

  class InvalidInvocationError < Error
    def initialize(step, object)
      valid_operations =
        case object
        when Array
          "Array index (0, 1, 2, etc.) or any Array methods (first, last, size, etc.)"
        when Hash
          "Any Hash key: #{object.keys.join(", ")}"
        else
          "Any method available on #{object.class}"
        end

      super(<<~STRING.chomp
        Cannot invoke "#{step}" on #{object.class}.

        Valid operations include: #{valid_operations}
      STRING
      )
    end
  end

  class InvalidTypeError < TypeError
    def initialize(object, expected_type, **opts)
      message = "Expected #{expected_type}, got #{object.class}"
      message += " for #{opts[:for]}" if opts[:for].present?

      super(message)
    end
  end
end
