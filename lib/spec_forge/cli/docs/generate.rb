# frozen_string_literal: true

module SpecForge
  class CLI
    class Docs < Command
      module Generate
        def generate_documentation
          generator = Documentation::Generators::OpenAPI["3.0"]
          output = generator.generate(use_cache: options.use_cache)

          generator.validate!(output) unless options.skip_validation

          # Determine output format and path
          file_format = determine_file_format
          file_path = determine_output_path(file_format)

          content =
            if file_format == "json"
              JSON.pretty_generate(output)
            else
              output.to_yaml(stringify_names: true)
            end

          ::File.write(file_path, content)

          file_path
        end

        private

        def determine_file_format
          file_format = options.format&.downcase || "yml"
          validate_format!(file_format)

          file_format
        end

        def validate_format!(format)
          return if VALID_FORMATS.include?(format)

          raise ArgumentError,
            "Invalid format #{format.in_quotes}. Valid formats: #{VALID_FORMATS.join_map(", ", &:in_quotes)}"
        end

        def determine_output_path(format)
          if options.output
            Pathname.new(options.output)
          else
            extension = (format == "json") ? "json" : "yml"
            SpecForge.openapi_path.join("generated", "openapi.#{extension}")
          end
        end
      end
    end
  end
end
