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

        puts format_with_indent("#{@color.decorate(symbol, style, color)} #{message}", indent:)
      end

      def success(message, indent: 0)
        action(:success, message, color: :green, indent:)
      end

      def error(message, indent: 0)
        action(:error, message, color: :red, indent:)
      end

      ##########################################################################

      def blueprint_start(blueprint)
        return if verbose?

        puts ""
        puts @color.bold("Running #{blueprint.file_name}...")
      end

      def step_start(step)
        return unless verbose?

        print_verbose_step_header(step)
      end

      def step_end(step, error: nil)
        if error.nil?
        else
          step_failure(step, error)
        end
      end

      def blueprint_end(blueprint, success: true)
        return unless verbose?

        header_length = LINE_LENGTH - 15

        if success
          puts @color.bold.green("━" * header_length)
        else
          puts @color.bold.red("━" * header_length)
        end

        puts ""
      end

      def forge_end(forge)
        puts "\n\n"

        if forge.failures.size > 0
          puts "Failures:\n\n"

          forge.failures
            .group_by_key(:step)
            .each_with_index do |(step, failures), index|
              line = step.source.line_number.to_s.rjust(2, "0")
              location = @color.bright_blue("#{index + 1}) [#{step.source.file_name}:#{line}]")

              puts format_with_indent("#{location} #{@color.white(step.name)}", indent: 1)

              failures.each do |failure|
                example = failure[:example]

                puts format_with_indent(example[:description], indent: 3)
                puts format_with_indent(@color.red(example[:exception][:message].strip), indent: 4)

                puts ""
              end
            end

        end

        puts format_stats(forge)
        puts ""
        puts @color.dim("Finished in #{sprintf("%.2g", forge.timer.time_elapsed)}s")
      end

      private

      def format_with_indent(message, indent: 0)
        base_indent = "  "  # 2 spaces
        nested_indent = " " * ((indent || 0) * 2)  # 2 more spaces per level

        "#{base_indent}#{nested_indent}#{message.gsub("\n", "\n#{base_indent}#{nested_indent}")}"
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

      def step_failure(step, error)
        return unless error.is_a?(Error::ExpectationFailure)

        error.failed_examples.each do |example|
          if verbose?
            # Print out the error
            message = example[:exception][:message].strip.prepend("\n")

            error("#{example[:description]} #{message}", indent: 1)

            # puts JSON.pretty_generate(example[:exception][:backtrace]) # DEBUG

            puts ""
            next
          end

          print @color.red("F")
        end
      end

      def format_stats(forge)
        blueprint_count = forge.blueprints.size
        step_count = forge.blueprints.sum { |b| b.steps.size }
        expect_count = forge.blueprints.sum { |b| b.steps.sum { |s| s.expects&.size || 0 } }
        failures_count = forge.failures.size

        blueprints = "#{blueprint_count} #{"blueprint".pluralize(blueprint_count)}"
        steps = "#{step_count} #{"step".pluralize(step_count)}"
        expected = "#{expect_count} #{"expectation".pluralize(expect_count)}"
        failures = "#{failures_count} #{"failures".pluralize(failures_count)}"

        "#{blueprints}, #{steps}, #{expected}, #{failures}"
      end
    end
  end
end
