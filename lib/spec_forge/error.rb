# frozen_string_literal: true

module SpecForge
  #
  # Base error class for all SpecForge-specific exceptions
  #
  class Error < StandardError
    #
    # Raised when a provided Faker class name doesn't exist
    # Provides helpful suggestions for similar class names
    #
    # @example
    #   Attribute::Faker.new("faker.invalid.method")
    #   # => InvalidFakerClassError: Undefined Faker class "invalid". Did you mean? name, games, ...
    #
    class InvalidFakerClassError < Error
      #
      # A spell checker for Faker classes
      #
      # @return [DidYouMean::SpellChecker]
      #
      CLASS_CHECKER = DidYouMean::SpellChecker.new(
        dictionary: Faker::Base.descendants.map { |c| c.to_s.downcase.gsub!("::", ".") }
      )

      def initialize(input)
        corrections = CLASS_CHECKER.correct(input)

        super(<<~STRING.chomp
          Undefined Faker class "#{input}". #{DidYouMean::Formatter.message_for(corrections)}

          For available classes, please check https://github.com/faker-ruby/faker/blob/main/GENERATORS.md.
        STRING
        )
      end
    end

    #
    # Raised when a provided method for a Faker class doesn't exist
    # Provides helpful suggestions for similar method names
    #
    # @example
    #   Attribute::Faker.new("faker.name.invlaid")
    #   # => InvalidFakerMethodError: Undefined Faker method "invlaid" for "Faker::Name".
    #                                 Did you mean? first_name, last_name, ...
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
    # Raised when an unknown transform function is referenced
    # Indicates when a transform name isn't supported
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
    # Raised when a step in an invocation chain is invalid
    # Provides detailed information about where in the chain the error occurred
    #
    # @example
    #   variable_attr = Attribute::Variable.new("variables.user.invalid_method")
    #   variable_attr.resolved
    #   # => InvalidInvocationError: Cannot invoke "invalid_method" on User
    #
    class InvalidInvocationError < Error
      def initialize(step, object, resolution_path = {})
        @step = step
        @object = object
        @resolution_path = resolution_path

        object_class =
          case object
          when Data
            object.class.name || "Data"
          when Struct
            object.class.name || "Struct"
          else
            object.class
          end

        super(<<~STRING.chomp
          Cannot invoke "#{step}" on #{object_class}
          #{resolution_path_message}
        STRING
        )
      end

      #
      # Creates a new InvalidInvocationError with a new resolution path
      #
      # @param path [Hash] The steps taken up until this point
      #
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
    # An extended version of TypeError with better error messages
    # Makes it easier to understand type mismatches in the codebase
    #
    # @example
    #   raise Error::InvalidTypeError.new(123, String, for: "name parameter")
    #   # => Expected String, got Integer for name parameter
    #
    class InvalidTypeError < Error
      def initialize(object, expected_type, **opts)
        if expected_type.instance_of?(Array)
          expected_type = expected_type.to_or_sentence
        end

        message = "Expected #{expected_type}, got #{object.class}"
        message += " for #{opts[:for]}" if opts[:for].present?

        super(message)
      end
    end

    class MissingVariableError < Error
      def initialize(variable_name, available_variables: [])
        message = "Undefined variable \"#{variable_name}\""

        checker = DidYouMean::SpellChecker.new(dictionary: available_variables)
        suggestions = checker.correct(variable_name.to_s)

        message += ". #{DidYouMean::Formatter.message_for(suggestions)}" if suggestions.size > 0

        if available_variables.size > 0 && available_variables.size <= 5
          message += ".\nAvailable: #{available_variables.join_map(", ", &:in_quotes)}"
        end

        super(message)
      end
    end

    #
    # Raised when a YAML structure doesn't match expectations
    # Acts as a container for multiple validation errors
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
    # Raised when an unknown factory build strategy is provided
    # Indicates when a strategy string doesn't match supported options
    #
    class InvalidBuildStrategy < Error
      def initialize(build_strategy)
        valid_strategies = Attribute::Factory::BUILD_STRATEGIES.to_or_sentence

        super(<<~STRING.chomp
          Unknown build strategy "#{build_strategy}" referenced in spec.

          Valid strategies include: #{valid_strategies}
        STRING
        )
      end
    end

    class LoadStepError < Error
      def initialize(error, step, depth = 0)
        step_name = step[:name].presence || "(unnamed)"
        line_info = step[:line_number] ? " (line #{step[:line_number]})" : ""

        message = "Step: #{step_name}#{line_info}"

        cause_message = if error.is_a?(LoadStepError)
          "\n#{error.message}"
        else
          # Final error - add spacing and the actual problem
          error_lines = error.message.split("\n").map(&:strip).reject(&:empty?)
          if error_lines.size > 1
            "\n\nCaused by:\n  " + error_lines.join("\n  ")
          else
            "\n\nCaused by: #{error.message}"
          end
        end

        super(message + cause_message)
      end
    end

    #
    # Raised when the provided matcher name does not defined with RSpec
    #
    class UndefinedMatcherError < Error
      def initialize(matcher_name)
        matcher_categories = {
          Equality: ["matcher.eq", "matcher.eql", "matcher.equal"],
          Types: ["kind_of.string", "kind_of.integer", "kind_of.array", "kind_of.hash"],
          Truthiness: ["be.true", "be.false", "be.nil"],
          Comparison: ["be.within", "be.between", "be.greater_than", "be.less_than"],
          Collections: ["matcher.include", "matcher.contain_exactly", "matcher.all"],
          Strings: ["/regex/", "matcher.start_with", "matcher.end_with"]
        }

        formatted_categories =
          matcher_categories.join_map("\n") do |category, matchers|
            "  #{category}: #{matchers.join(", ")}"
          end

        super(<<~STRING.chomp
          Undefined matcher method "#{matcher_name}" is not available in RSpec matchers.

          Common matchers you can use:
          #{formatted_categories}

          For the complete list of available matchers, check the RSpec documentation:
          https://rspec.info/documentation/3.12/rspec-expectations/RSpec/Matchers.html
        STRING
        )
      end
    end

    #
    # Raised when a callback is referenced in config but hasn't been defined
    #
    class UndefinedCallbackError < Error
      def initialize(callback_name, available_callbacks = [])
        message = "The callback #{callback_name.in_quotes} was referenced but hasn't been defined."

        message +=
          if available_callbacks.any?
            <<~STR.chomp

              Available callbacks are: #{available_callbacks.join_map(", ", &:in_quotes)}
            STR
          else
            <<~STR.chomp

              No callbacks have been defined yet. Register callbacks with:

                SpecForge.register_callback(:#{callback_name}) do |context|
                  # Your callback code
                end
            STR
          end

        super(message)
      end
    end

    #
    # Raised when an OpenAPI specification fails validation
    #
    # This error indicates that the generated OpenAPI document contains
    # validation errors according to the OpenAPI specification standards.
    # It's typically raised after attempting to validate a generated specification.
    #
    # @example
    #   begin
    #     generator.validate!(openapi_spec)
    #   rescue SpecForge::Error::InvalidOASDocument
    #     puts "Generated specification has validation errors"
    #   end
    #
    class InvalidOASDocument < Error
    end

    class ExpectationFailure < Error
      attr_reader :failed_examples

      def initialize(failed_examples)
        @failed_examples = failed_examples

        super("Failed expectations (#{@failed_examples.size})")
      end
    end

    #
    # Raised when JSON shape validation fails
    #
    # Contains structured failure information for all validation errors
    # discovered during shape checking.
    #
    # @example Single failure
    #   failures = [{path: ".id", expected_type: String, actual_type: Integer, actual_value: 42}]
    #   raise SchemaValidationFailure.new(failures)
    #
    # @example Multiple failures
    #   failures = [
    #     {path: ".id", expected_type: String, actual_type: Integer, actual_value: 42},
    #     {path: ".email", expected_type: String, actual_type: NilClass, actual_value: nil}
    #   ]
    #   raise SchemaValidationFailure.new(failures)
    #
    class SchemaValidationFailure < Error
      attr_reader :failures

      def initialize(failures)
        @failures = failures

        message =
          if failures.size == 1
            format_failure(failures.first)
          else
            failures.join_map("\n") do |failure|
              format_failure(failure)
            end
          end

        super(message)
      end

      private

      def format_failure(failure)
        expected_types =
          if failure[:expected_type].size == 1
            failure[:expected_type].first
          else
            failure[:expected_type].to_or_sentence
          end

        "#{failure[:path]}: expected #{expected_types}, got #{failure[:actual_type]} (#{failure[:actual_value].inspect})"
      end
    end

    class ContentValidationFailure < Error
      attr_reader :failures

      def initialize(failures)
        @failures = failures
        super(format_failures(failures))
      end

      private

      def format_failures(failures)
        if failures.size == 1
          failure = failures.first
          "#{failure[:path]}: #{failure[:message]}"
        else
          failures.join_map("\n") { |f| "#{f[:path]}: #{f[:message]}" }
        end
      end
    end
  end
end
