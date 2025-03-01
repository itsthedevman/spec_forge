# frozen_string_literal: true

module SpecForge
  # Pass into to_sentence
  OR_CONNECTOR = {
    last_word_connector: ", or ",
    two_words_connector: " or ",
    # This is a minor performance improvement to avoid locales being loaded
    # This will need to be removed if locales are added
    locale: false
  }.freeze

  private_constant :OR_CONNECTOR

  class Error < StandardError; end

  #
  # Raised by Attribute::Faker when a provided classname does not exist in Faker
  #
  class InvalidFakerClassError < Error
    CLASS_CHECKER = DidYouMean::SpellChecker.new(
      dictionary: Faker::Base.descendants.map { |c| c.to_s.downcase.gsub!("::", ".") }
    )

    def initialize(input)
      corrections = CLASS_CHECKER.correct(input)

      super(<<~STRING.chomp
        Undefined Faker class "#{input}". #{DidYouMean::Formatter.message_for(corrections)}

        For available classes, please check https://github.com/faker-ruby/faker#generators.
      STRING
      )
    end
  end

  #
  # Raised by Attribute::Faker when a provided method for a Faker class does not exist.
  #
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

  #
  # Raised by Attribute::Transform when the provided transform function is not valid
  #
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

  #
  # Raised by Attribute::Chainable when an step in the invocation chain is invalid
  #
  class InvalidInvocationError < Error
    def initialize(step, object, resolution_path = {})
      @step = step
      @object = object
      @resolution_path = resolution_path

      super(<<~STRING.chomp
        Cannot invoke "#{step}" on #{object.class}
        #{resolution_path_message}
      STRING
      )
    end

    def with_resolution_path(path)
      self.class.new(@step, @object, path)
    end

    private

    def resolution_path_message
      return "" if @resolution_path.empty?

      message =
        @resolution_path.map.with_index do |(path, description), index|
          "#{index + 1}. #{path} --> #{description}"
        end.join("\n")

      "\nResolution path:\n#{message}"
    end
  end

  #
  # An extended version of TypeError to make things easier when reporting invalid types
  #
  class InvalidTypeError < Error
    def initialize(object, expected_type, **opts)
      if expected_type.instance_of?(Array)
        expected_type = expected_type.to_sentence(**OR_CONNECTOR)
      end

      message = "Expected #{expected_type}, got #{object.class}"
      message += " for #{opts[:for]}" if opts[:for].present?

      super(message)
    end
  end

  #
  # Raised by Attribute::Variable when the provided variable name is not defined
  #
  class MissingVariableError < Error
    def initialize(variable_name)
      super("Undefined variable \"#{variable_name}\" referenced in expectation")
    end
  end

  #
  # Raised by Normalizer when any errors are returned. Acts like a grouping of errors
  #
  class InvalidStructureError < Error
    def initialize(errors)
      message = errors.to_a.join_map("\n") do |error|
        next error if error.is_a?(SpecForge::Error)

        # Normal errors, let's get verbose
        backtrace = SpecForge.backtrace_cleaner.clean(error.backtrace)
        "#{error.inspect}\n  # ./#{backtrace.join("\n  # ./")}\n"
      end

      super(message)
    end
  end

  #
  # Raised by Attribute::Factory when an unknown build strategy is provided
  #
  class InvalidBuildStrategy < Error
    def initialize(build_strategy)
      valid_strategies = Attribute::Factory::BUILD_STRATEGIES.to_sentence(**OR_CONNECTOR)

      super(<<~STRING.chomp
        Unknown build strategy "#{build_strategy}" referenced in spec.

        Valid strategies include: #{valid_strategies}
      STRING
      )
    end
  end

  class SpecLoadError < Error
    def initialize(error, file_path)
      message = "Error loading spec file: #{file_path}\n"
      causes = error.message.split("\n").map(&:strip).reject(&:empty?)

      message +=
        if causes.size > 1
          "Causes:\n  - #{causes.join_map("\n  - ")}"
        else
          "Cause: #{error}"
        end

      super(message)
    end
  end
end
