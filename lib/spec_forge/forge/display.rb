# frozen_string_literal: true

module SpecForge
  class Forge
    class Display
      LINE_LENGTH = 120

      attr_predicate :verbose

      def initialize(verbose: false)
        @verbose = verbose
        @color = Pastel.new
      end

      def blueprint_start(blueprint)
        return if verbose?

        puts ""
        puts @color.bold("Running #{blueprint.file_name}...")
      end

      def blueprint_end(blueprint, success: true)
        header_length = verbose? ? LINE_LENGTH - 15 : LINE_LENGTH * 0.60

        if success
          puts @color.bold.green("━" * header_length)
        else
          puts @color.bold.red("━" * header_length)
        end

        puts ""
      end

      def forge_end(forge)
        # TODO: Add run metrics
        puts @color.dim("Completed in #{sprintf("%.2g", forge.timer.time_elapsed)}s")
      end

      def step_start(step)
        if verbose?
          print_verbose_step_header(step)
        else
          # Print without newline, we'll overwrite it later
          print "  Running: #{step_name(step)}..."
        end
      end

      def step_end(step, error: nil)
        if error.nil? # success
          if verbose?
            puts ""
          else
            puts "  #{@color.green("✓")} #{step_name(step)}"
          end

          return
        end

        # Handle shape validation failures
        if error.is_a?(Error::ShapeValidationFailure)
          format_shape_failures(error.failures)
          puts ""
          puts "  #{@color.red("✗")} #{step_name(step)}" unless verbose?
          return
        end

        return unless error.is_a?(Error::ExpectationFailure)

        error.failed_examples.each do |example|
          # Print out the error
          message = example[:exception][:message]
            .strip # Remove all leading/trailing whitespace. RSpec likes to add that to the exception
            .prepend("\n") # Ensure there is a leading whitespace
            .gsub("\n", "\n        ") # Now add tabbing

          error("#{example[:description]} #{message}", indent: 1)

          # puts JSON.pretty_generate(example[:exception][:backtrace]) # DEBUG

          puts ""
          next if verbose?

          puts "  #{@color.red("✗")} #{step_name(step)}"
        end
      end

      def action(type, message, color: :bright_black, style: :clear, indent: 0)
        return unless verbose?

        symbol =
          case type
          when :request
            "→"
          when :store
            "▸"
          when :call
            "●"
          when :debug
            "⚑"
          when :success
            "✓"
          when :error
            "✗"
          end

        base_indent = "  "  # 2 spaces
        nested_indent = " " * ((indent || 0) * 2)  # 2 more spaces per level

        puts "#{base_indent}#{nested_indent}#{@color.decorate(symbol, style, color)} #{message}"
      end

      def success(message, indent: 0)
        action(:success, message, color: :green, indent:)
      end

      def error(message, indent: 0)
        action(:error, message, color: :red, indent:)
      end

      private

      def format_shape_failures(failures)
        if failures.size == 1
          failure = failures.first
          msg = "Response body shape at #{failure[:path]} - expected #{format_expected_type(failure[:expected_type])}, got #{failure[:actual_type]} (#{truncate_value(failure[:actual_value])})"
          error(msg, indent: 1)
        else
          error("Response body shape", indent: 1)
          failures.each do |failure|
            msg = "#{failure[:path]} - expected #{format_expected_type(failure[:expected_type])}, got #{failure[:actual_type]} (#{truncate_value(failure[:actual_value])})"
            puts "      #{msg}"
          end
        end
      end

      def format_expected_type(expected_type)
        # Handle type unions (array of classes)
        if expected_type.is_a?(Array) && expected_type.all? { |item| item.is_a?(Class) }
          if expected_type.size == 1
            expected_type.first.to_s
          else
            expected_type.map(&:to_s).join(" or ")
          end
        else
          expected_type.to_s
        end
      end

      def truncate_value(value, max_length: 50)
        str = value.inspect
        (str.length > max_length) ? "#{str[0...max_length]}..." : str
      end

      def step_name(step)
        step.name.present? ? step.name : @color.dim("(Unnamed step: line #{step.source.line_number})")
      end

      def print_verbose_step_header(step)
        line = step.source.line_number.to_s.rjust(2, "0")
        location = @color.bright_blue("[#{step.source.file_name}:#{line}]")

        filler_size = LINE_LENGTH - location.length

        if step.name.present?
          name = @color.white(step.name)
          filler_size -= (name.size - 1)
        else
          name = @color.dim("(unnamed)")
          filler_size -= name.size
        end

        filler = @color.dim("*" * filler_size)

        puts "#{location} #{name} #{filler}"
        puts step.description if step.description.present?
      end
    end
  end
end
