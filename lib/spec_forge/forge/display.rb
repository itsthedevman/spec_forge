# frozen_string_literal: true

module SpecForge
  class Forge
    #
    # Handles formatted output for forge execution
    #
    # Display manages the console output during test runs, adapting
    # its verbosity based on the configured level (0-3). It formats
    # step headers, action indicators, expectation results, and
    # failure summaries.
    #
    class Display
      # Maximum line length for output formatting
      #
      # @return [Integer]
      LINE_LENGTH = 120

      # @return [Integer] Current verbosity level (0-3)
      attr_reader :verbosity_level

      #
      # Creates a new display handler with the specified verbosity level
      #
      # @param verbosity_level [Integer] Output verbosity (0=minimal, 1=verbose, 2=debug, 3=trace)
      #
      # @return [Display] A new display instance
      #
      def initialize(verbosity_level: 0)
        @verbosity_level = verbosity_level
        @color = Pastel.new
      end

      #
      # Returns whether display is in default (minimal) mode
      #
      # @return [Boolean] True if verbosity is 0
      #
      def default_mode?
        verbosity_level == 0
      end

      #
      # Returns whether display is in verbose mode or higher
      #
      # @return [Boolean] True if verbosity is 1 or higher
      #
      def verbose?
        verbosity_level >= 1
      end

      #
      # Returns whether display is in very verbose (debug) mode or higher
      #
      # @return [Boolean] True if verbosity is 2 or higher
      #
      def very_verbose?
        verbosity_level >= 2
      end

      #
      # Returns whether display is in maximum verbose (trace) mode
      #
      # @return [Boolean] True if verbosity is 3 or higher
      #
      def max_verbose?
        verbosity_level >= 3
      end

      def empty_line
        puts ""
      end

      # TODO: Documentation (see #format)
      def action(message, **options)
        return if default_mode?

        puts format(message, indent: 1, **options)
      end

      #
      # Displays a passing expectation indicator (green dot)
      #
      # @param message [String] The expectation message (unused in default mode)
      # @param indent [Integer] Indentation level
      #
      # @return [void]
      #
      def expectation_passed(message, indent: 0)
        return if verbose?

        print @color.green(".")
      end

      #
      # Displays a failing expectation indicator (red F)
      #
      # @param message [String] The expectation message (unused in default mode)
      # @param indent [Integer] Indentation level
      #
      # @return [void]
      #
      def expectation_failed(message, indent: 0)
        return if verbose?

        print @color.red("F")
      end

      #
      # Displays the result summary for a completed expectation
      #
      # @param failed_examples [Array] List of failed RSpec examples
      # @param total_count [Integer] Total number of assertions in the expectation
      # @param index [Integer] The expectation index (1-based)
      # @param show_index [Boolean] Whether to display the index prefix
      #
      # @return [void]
      #
      def expectation_finished(failed_examples:, total_count:, index: 0, show_index: false)
        return if default_mode?

        failed_count = failed_examples.size

        print format_with_indent("#{index}:  ", indent: 1) if show_index

        if failed_count == 0
          action(
            "(#{total_count}/#{total_count} passed)",
            symbol: :success,
            symbol_styles: :green,
            indent: show_index ? 0 : 1
          )
        else
          action(
            "(#{failed_count}/#{total_count} failed)",
            symbol: :error,
            symbol_styles: :red,
            indent: show_index ? 0 : 1
          )
        end

        return if failed_examples.blank?

        puts ""

        failed_examples.each do |example|
          message = example[:exception][:message].strip.prepend("\n")

          puts format_with_indent("#{example[:description]} #{@color.red(message)}", indent: 3)
          # puts JSON.pretty_generate(example[:exception][:backtrace]) # DEBUG

          puts ""
        end
      end

      # TODO: Documentation
      def forge_start(forge)
        line = "#{@color.magenta("[forge]")} Ignited"
        filler = @color.magenta("━" * (LINE_LENGTH - 15)) # [forge] ignited

        puts ""
        puts "#{line} #{filler}"
      end

      # TODO: Documentation
      def blueprint_start(blueprint)
        puts ""

        visual_length = "[#{blueprint.name}] Setup".size
        line = "#{@color.bright_blue("[#{blueprint.name}]")} Setup"
        filler = @color.bright_blue("━" * (LINE_LENGTH - visual_length))

        puts "#{line} #{filler}"
      end

      #
      # Called when a step begins execution
      #
      # @param step [Step] The step starting
      #
      # @return [void]
      #
      def step_start(step)
        return if default_mode?

        line = step.source.line_number.to_s.rjust(2, "0")

        line = "#{step.source.file_name}:#{line}"
        line = "#{step.included_by.file_name}→#{line}" if step.included_by.present?

        visual_length = line.size + 2
        line = @color.cyan("[#{line}]")

        filler_size = LINE_LENGTH - visual_length

        # +1 offset to match forge/blueprint headers
        if step.name.present?
          name = step.name
          filler_size -= (name.size + 1)
        else
          name = @color.dim("(unnamed)")
          filler_size -= 10 # (unnamed) + 1
        end

        filler = @color.cyan("━" * filler_size)

        puts "#{line} #{name} #{filler}"
      end

      #
      # Called when a step finishes execution
      #
      # @param forge [Forge] The forge instance
      # @param step [Step] The step that finished
      # @param error [Exception, nil] Any error that occurred
      #
      # @return [void]
      #
      def step_end(forge, step, error: nil)
        return unless verbose?

        puts ""

        if max_verbose? || (very_verbose? && error)
          indent = error ? 3 : 1

          details = format_debug_details(forge, step, indent:)
          return if details.blank?

          if error
            puts format_with_indent(@color.red(error.message), indent:) unless error.is_a?(Error::ExpectationFailure)
            puts ""
            puts format_with_indent(@color.dim("━" * (LINE_LENGTH * 0.75)), indent:)
            puts ""
          end

          puts details
        end
      end

      #
      # Called when a blueprint finishes execution
      #
      # @param blueprint [Blueprint] The blueprint that finished
      # @param success [Boolean] Whether all steps passed
      #
      # @return [void]
      #
      def blueprint_end(blueprint, success: true)
        return if default_mode?

        style = success ? :bright_green : :bright_red

        visual_length = "[#{blueprint.name}] Cleanup".size
        line = "#{@color.decorate("[#{blueprint.name}]", style)} Cleanup"
        length = LINE_LENGTH - visual_length

        filler = @color.decorate("━" * length, style)

        puts "#{line} #{filler}"
      end

      #
      # Called when the entire forge run completes
      #
      # @param forge [Forge] The forge instance
      #
      # @return [void]
      #
      def forge_end(forge)
        line = "#{@color.magenta("[forge]")} Quenched"
        filler = @color.magenta("━" * (LINE_LENGTH - 16))

        puts ""
        puts "#{line} #{filler}"
      end

      # TODO: Documentation
      def stats(forge)
        puts ""

        if forge.failures.size > 0
          puts "Failures:\n\n"
          puts format_failures(forge.failures)
        end

        puts format_stats(forge)
        puts ""
        puts @color.dim("Finished in #{sprintf("%.2g", forge.timer.time_elapsed)}s")
      end

      private

      def format(message, indent: 0, message_styles: nil, symbol: nil, symbol_styles: nil)
        symbol =
          case symbol
          when :right_arrow
            "→"
          when :flag
            "⚑"
          when :checkmark, :success
            "✓"
          when :x, :error
            "✗"
          else
            ""
          end

        if symbol_styles.present?
          symbol = @color.decorate(symbol, *Array.wrap(symbol_styles))
        end

        if message_styles.present?
          message = @color.decorate(message, *Array.wrap(message_styles))
        end

        message = "#{symbol} #{message}" if symbol.present?

        format_with_indent(message, indent:)
      end

      def format_with_indent(message, indent: 0)
        indent = (indent == 0) ? "" : " " * (indent * 2) # 2 spaces

        "#{indent}#{message.gsub("\n", "\n#{indent}")}"
      end

      def format_failures(failures)
        output = []

        failures
          .group_by_key(:step)
          .each_with_index do |(step, failures), index|
            line = step.source.line_number.to_s.rjust(2, "0")
            location = @color.bright_blue("#{index + 1})  [#{step.source.file_name}:#{line}]")

            output << format_with_indent("#{location} #{@color.white(step.name)}", indent: 1)
            output << ""

            failures.each do |failure|
              example = failure[:example]
              message = example[:exception][:message].strip.prepend("\n")

              output << format_with_indent("#{example[:description]} #{@color.red(message)}", indent: 3)
              output << ""
            end

            output << ""
          end

        output.join("\n")
      end

      def format_stats(forge)
        stats = forge.stats

        blueprint_count = stats[:blueprints]
        step_count = stats[:steps]
        passed_count = stats[:passed]
        failures_count = stats[:failed]

        blueprints = "#{blueprint_count} #{"blueprint".pluralize(blueprint_count)}"
        steps = "#{step_count} #{"step".pluralize(step_count)}"
        passed = "#{passed_count} #{"expectation".pluralize(passed_count)}"
        failures = "#{failures_count} #{"failure".pluralize(failures_count)}"

        message = "#{blueprints}, #{steps}, #{passed}, #{failures}"

        if failures_count > 0
          @color.red(message)
        else
          @color.green(message)
        end
      end

      def format_schema_for_display(schema)
        return if schema.blank?

        case schema
        when Hash
          if schema[:pattern]
            # Array with pattern - show type + pattern structure
            {
              type: Type.to_string(*schema[:type]),
              pattern: format_schema_for_display(schema[:pattern])
            }
          elsif schema[:structure]
            # Hash with structure - just recurse into the fields (no type: hash clutter)
            schema[:structure].transform_values { |field| format_schema_for_display(field) }
          elsif schema[:type]
            # Simple field - just convert the type
            Type.to_string(*schema[:type])
          else
            # Unknown structure, pass through as-is
            schema
          end
        else
          # Not a hash, return as-is
          schema
        end
      end

      def format_debug_details(forge, step, indent: 0)
        output = []

        variables = forge.variables.to_hash.symbolize_keys
        if (request = variables.delete(:request))
          output << format_with_indent("Request:", indent:)
          output << format_with_indent(request.to_h.to_yaml(stringify_names: true).sub("---\n", ""), indent: indent + 1)
        end

        if (response = variables.delete(:response))
          output << format_with_indent("Response:", indent:)
          output << format_with_indent(response.to_h.to_yaml(stringify_names: true).sub("---\n", ""), indent: indent + 1)
        end

        if variables.present?
          output << format_with_indent("Variables:", indent:)
          output << format_with_indent(variables.to_h.to_yaml(stringify_names: true).sub("---\n", ""), indent: indent + 1)
        end

        if (expects = step.expects) && expects.present?
          expectations = expects.map do |expect|
            expect = expect.to_h

            if (schema = expect.dig(:json, :schema)) && schema.present?
              expect[:json][:schema] = format_schema_for_display(schema)
            end

            expect
              .compact_blank
              .deep_stringify_keys
              .deep_transform_values do |value|
              value = Attribute.resolve_as_matcher_proc.call(value)

              if value.respond_to?(:description)
                value.description
              else
                value
              end
            end
          end

          if expectations.size > 0
            output << format_with_indent("Expectations:", indent:)
            output << format_with_indent(expectations.to_yaml(stringify_names: true).sub("---\n", ""), indent: indent + 1)
          end
        end

        output.join("\n")
      end
    end
  end
end
