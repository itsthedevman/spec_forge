# frozen_string_literal: true

module SpecForge
  class CLI
    #
    # Command for generating and serving API documentation
    #
    # Provides CLI commands for generating OpenAPI specifications from tests
    # and serving them through a web interface.
    #
    # @example Generating OpenAPI documentation
    #   spec_forge docs generate
    #
    # @example Starting documentation server
    #   spec_forge docs serve
    #
    class Docs < Command
      VALID_FORMATS = %w[yml yaml json].freeze

      command_name "docs"
      syntax "docs <action>"
      summary "Generate and serve API documentation from SpecForge tests"
      description "Generate OpenAPI specifications from your SpecForge tests or serve them through a web interface. Supports multiple output formats and caching for faster regeneration."

      example "docs generate",
        "Generates OpenAPI documentation from all tests"

      example "docs generate --use-cache",
        "Uses cached test data if available, otherwise runs tests first"

      example "docs generate --format=json",
        "Generates documentation in JSON format instead of YAML"

      example "docs serve",
        "Starts a local server to view the generated documentation"

      option "--use-cache",
        "Use cached test data if available, otherwise run tests to generate cache"

      option "--format=FORMAT",
        "The file format of the output: yml/yaml or json (default: yml)"

      option "--output=PATH",
        "Custom output path for generated documentation"

      #
      # Executes the docs command with the specified action
      #
      # Supports 'generate' to create OpenAPI files and 'serve' to start a documentation server.
      # The generate action can output in multiple formats and supports caching for performance.
      #
      # @return [void]
      # @raise [ArgumentError] If an invalid action is provided
      #
      def call
        case (action = arguments.first)
        when "generate"
          generate_documentation
        when "serve"
          serve_documentation
        else
          raise ArgumentError, "Unexpected action #{action&.in_quotes}. Expected \"generate\" or \"serve\""
        end
      end

      private

      def generate_documentation
        renderer_class = Documentation::Renderers::OpenAPI["3.0"]

        # Determine output format and path
        file_format = options.format&.downcase || "json"
        validate_format!(file_format)

        Documentation.render(
          renderer_class,
          path: determine_output_path(file_format),
          use_cache: options.use_cache,
          file_format:
        )
      end

      def serve_documentation
        # This would be implemented later - placeholder for now
        puts "Documentation server functionality coming soon!"
        puts "For now, you can generate docs with 'spec_forge docs generate'"
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
