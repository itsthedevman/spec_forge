# frozen_string_literal: true

module SpecForge
  class CLI
    class Docs < Command
      #
      # Shared functionality for generating OpenAPI documentation
      #
      # This module contains the core logic for running tests, extracting endpoint
      # data, and generating OpenAPI specifications. It's used by both the Docs
      # and Serve commands to avoid duplication.
      #
      module Generate
        #
        # Generates OpenAPI documentation from blueprint test results
        #
        # Runs blueprints with the configured verbosity level, extracts endpoint
        # data, validates the specification (unless skipped), and writes the
        # output file in the specified format.
        #
        # @param base_path [String, Pathname, nil] Optional base path for blueprints
        #
        # @return [Pathname] Path to the generated documentation file
        #
        def generate_documentation(base_path: nil)
          document = Documentation::Builder.create_document!(
            base_path:,
            use_cache: !options.fresh,
            verbosity_level: determine_verbosity_level
          )
          generator_class = Documentation::OpenAPI["3.0"]
          output = generator_class.new(document).generate

          generator_class.validate!(output) unless options.skip_validation

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

        #
        # Determines verbosity level from command options
        #
        # @return [Integer] Verbosity level (0-3)
        #
        def determine_verbosity_level
          return 3 if options.trace
          return 2 if options.debug
          return 1 if options.verbose

          0
        end
      end
    end
  end
end
