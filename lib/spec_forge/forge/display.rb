module SpecForge
  class Forge
    class Display
      attr_predicate :verbose

      def initialize(verbose: false)
        @verbose = verbose
        @color = Pastel.new
      end

      # Non-verbose only
      def blueprint_start(blueprint)
        return if verbose?

        puts ""
        print @color.bold("Running #{blueprint.file_name}...")
        puts ""
      end

      # Both modes, but different behavior
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
        else
          # Clear entire line, then carriage return
          print "\e[2K\r"
          if success
            puts "  #{@color.green("✓")} #{step_name(step)}"
          else
            puts "  #{@color.red("✗")} #{step_name(step)}"
          end
        end
      end

      # Verbose only - for actions within a step
      def action(type, message, color: :bright_black)
        return unless verbose?

        symbol =
          case type
          when :request
            "→"
          when :store
            "▸"
          when :hook
            "↪"
          when :call
            "●"
          when :debug
            "⚑"
          when :success
            "✓"
          when :error
            "✗"
          end

        puts "  #{@color.decorate(symbol, color)} #{message}"
      end

      private

      def step_name(step)
        step.name.present? ? step.name : @color.dim("(Unnamed step: line #{step.source.line_number})")
      end

      def print_verbose_step_header(step)
        line = step.source.line_number.to_s.rjust(2, "0")
        location = @color.cyan("[#{step.source.file_name}:#{line}]")

        name = step.name.present? ? @color.white(step.name) : @color.dim("(unnamed)")
        filler = @color.dim("*" * (120 - location.length - name.length))

        puts "#{location} #{name} #{filler}"
        puts step.description if step.description.present?
      end
    end
  end
end
