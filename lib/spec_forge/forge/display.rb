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

      def blueprint_end(blueprint)
        puts ""
      end

      def forge_end(forge, success: true)
        header_length = verbose? ? LINE_LENGTH - 15 : LINE_LENGTH * 0.60

        if success
          puts @color.bold.green("━" * header_length)
        else
          puts @color.bold.red("━" * header_length)
        end

        # TODO: Add run metrics
        puts "" if verbose?

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
        # Clear entire line first, then carriage return. Clears up left over text
        print "\e[2K\r"

        if error.nil?
          if verbose?
            puts ""
          else
            puts "  #{@color.green("✓")} #{step_name(step)}"
          end

          return
        end

        raise error unless error.is_a?(Error::ExpectationFailure)

        example = error.failed_example
        error(example[:exception][:message], indent: 1)

        puts "  #{@color.red("✗")} #{step_name(step)}" unless verbose?
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
