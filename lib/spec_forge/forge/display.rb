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

      def expectation_finished(failed_examples:, total_count:, index: 0, show_index: false)
        return if default_mode?

        failed_count = failed_examples.size

        print format_with_indent("#{index}:  ", indent: 1) if show_index

        if failed_count == 0
          action(:success, "(#{total_count}/#{total_count} passed)", color: :green, indent: show_index ? 0 : 1)
        else
          action(:error, "(#{failed_count}/#{total_count} failed)", color: :red, indent: show_index ? 0 : 1)
        end

        return if failed_examples.blank?

        puts ""
        failed_examples.each do |example|
          # Print out the error
          message = example[:exception][:message].strip.prepend("\n")

          puts format_with_indent("#{example[:description]} #{@color.red(message)}", indent: 3)
          # puts JSON.pretty_generate(example[:exception][:backtrace]) # DEBUG

          puts ""
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

      def step_end(forge, step, error: nil)
        if error.nil?
          puts ""
        else
          step_failure(forge, step, error)
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
          puts format_failures(forge.failures)
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

      def step_failure(forge, step, error)
        return if default_mode? || max_verbose?

        indent = 3

        puts ""
        puts format_with_indent(@color.dim("━" * (LINE_LENGTH * 0.75)), indent:)
        puts ""

        variables = forge.variables.to_hash.symbolize_keys
        if (request = variables.delete(:request))
          puts format_with_indent("Request:", indent:)
          puts format_with_indent(request.to_h.deep_stringify_keys.to_yaml.sub("---\n", ""), indent: indent + 1)
        end

        if (response = variables.delete(:response))
          puts format_with_indent("Response:", indent:)
          puts format_with_indent(response.to_h.deep_stringify_keys.to_yaml.sub("---\n", ""), indent: indent + 1)
        end

        if variables.present?
          puts format_with_indent("Variables:", indent:)
          puts format_with_indent(variables.to_h.deep_stringify_keys.to_yaml.sub("---\n", ""), indent: indent + 1)
        end

        expectations = step.expects.map do |expect|
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
          puts format_with_indent("Expectations:", indent:)
          puts format_with_indent(expectations.to_yaml.sub("---\n", ""), indent: indent + 1)
        end
      end

      def format_failures(failures)
        output = ""

        failures
          .group_by_key(:step)
          .each_with_index do |(step, failures), index|
            line = step.source.line_number.to_s.rjust(2, "0")
            location = @color.bright_blue("#{index + 1})  [#{step.source.file_name}:#{line}]")

            output += format_with_indent("#{location} #{@color.white(step.name)}", indent: 1)
            output += "\n\n"

            failures.each do |failure|
              example = failure[:example]
              message = example[:exception][:message].strip.prepend("\n")

              output += format_with_indent("#{example[:description]} #{@color.red(message)}", indent: 3)
              output += "\n\n"
            end
          end

        output
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
    end
  end
end
