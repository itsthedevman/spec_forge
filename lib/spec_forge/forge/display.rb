# frozen_string_literal: true

module SpecForge
  class Forge
    class Display
      LINE_LENGTH = 120

      attr_reader :verbosity_level

      def initialize(verbosity_level: 0)
        @verbosity_level = verbosity_level
        @color = Pastel.new
      end

      def default_mode?
        verbosity_level == 0
      end

      def verbose?
        verbosity_level >= 1
      end

      def very_verbose?
        verbosity_level >= 2
      end

      def max_verbose?
        verbosity_level >= 3
      end

      def action(type, message, color: :bright_black, style: :clear, indent: 0)
        return if default_mode?

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

      def expectation_passed(message, indent: 0)
        return if verbose?

        print @color.green(".")
      end

      def expectation_failed(message, indent: 0)
        return if verbose?

        print @color.red("F")
      end

      # [simple_lifecycle:08] Create a user *********************************************
      #   → POST /api/users
      #     Expect 1: ✓ (1/1 passed)
      #     Expect 2: ✓ (2/2 passed)
      #     Expect 3: ✗ (1/3 failed)
      #       JSON size
      #         expected: 3
      #         got: 5
      #   ▸ Store "user_id"
      #   ▸ Store "created_email"

      def expectation_finished(failed_count:, total_count:, index: 0, show_index: false)
        print format_with_indent("#{index}: ", indent: 1) if show_index

        if failed_count == 0
          action(:success, "(#{total_count}/#{total_count} passed)", color: :green, indent: show_index ? 0 : 1)
        else
          action(:error, "(#{failed_count}/#{total_count} failed)", color: :red, indent: show_index ? 0 : 1)
        end
      end

      ##########################################################################

      def blueprint_start(blueprint)
        return if verbose?

        puts ""
        puts @color.bold("Running #{blueprint.file_name}...")
      end

      def step_start(step)
        return if default_mode?

        print_verbose_step_header(step)
      end

      def step_end(step, error: nil)
        if error.nil?
          puts ""
        else
          step_failure(step, error)
        end
      end

      def blueprint_end(blueprint, success: true)
        return if default_mode?

        header_length = LINE_LENGTH - 15

        if success
          puts @color.bold.green("━" * header_length)
        else
          puts @color.bold.red("━" * header_length)
        end
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
                message = example[:exception][:message].strip.prepend("\n")

                puts format_with_indent("#{example[:description]} #{@color.red(message)}", indent: 2)
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
        indent = (indent == 0) ? "" : " " * (indent * 2) # 2 spaces

        "#{indent}#{message.gsub("\n", "\n#{indent}")}"
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

            puts format_with_indent("#{example[:description]} #{@color.red(message)}", indent: 2)
            # puts JSON.pretty_generate(example[:exception][:backtrace]) # DEBUG

            puts ""
            next
          end
        end
      end

      def format_stats(forge)
        stats = forge.stats

        blueprint_count = stats[:blueprints]
        step_count = stats[:steps]
        passed_count = stats[:passed]
        failures_count = stats[:failed]

        blueprints = "#{blueprint_count} #{"blueprint".pluralize(blueprint_count)}"
        steps = "#{step_count} #{"step".pluralize(step_count)}"
        passed = "#{passed_count} #{"example".pluralize(passed_count)}"
        failures = "#{failures_count} #{"failures".pluralize(failures_count)}"

        message = "#{blueprints}, #{steps}, #{passed}, #{failures}"

        if failures_count > 0
          @color.red(message)
        else
          @color.green(message)
        end
      end
    end
  end
end
