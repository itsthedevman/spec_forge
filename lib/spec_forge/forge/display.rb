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

      def forge_end(forge)
        puts ""

        header_length = verbose? ? LINE_LENGTH - 15 : LINE_LENGTH * 0.60
        puts @color.bold.green("━" * header_length)

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

      def step_end(step, success: true)
        if verbose?
          puts ""
          return
        end

        # Clear entire line first, then carriage return. Clears up left over text
        print "\e[2K\r"

        if success
          puts "  #{@color.green("✓")} #{step_name(step)}"
        else
          puts "  #{@color.red("✗")} #{step_name(step)}"
        end
      end

      def action(type, message, color: :bright_black, style: :clear)
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

        puts "  #{@color.decorate(symbol, style, color)} #{message}"
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
