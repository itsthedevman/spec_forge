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
      command_name "docs"
      syntax "docs <action>"
      summary "TODO"

      option "--use-cache", "Use cached test data instead of running tests again"
      option "--format=FORMAT", "The file format of the output: yml/yaml or json"

      #
      # Executes the docs command with the specified action
      #
      # Supports 'generate' to create OpenAPI files and 'serve' to start a documentation server.
      #
      # @return [void]
      # @raise [ArgumentError] If an invalid action is provided
      #
      def call
        case (action = arguments.first)
        when "generate"
          renderer_class = Documentation::Renderers::OpenAPI["3.0"]

          format = validate_option_format

          Documentation.render(
            renderer_class,
            path: SpecForge.openapi_path.join("generated", "openapi.#{format}"),
            use_cache: options.use_cache
          )
        when "serve"
          nil
        else
          raise ArgumentError, "Unexpected action #{action&.in_quotes}. Expected \"generate\" or \"serve\""
        end
      end

      private

      def validate_option_format
        if options.format.downcase == "json"
          "json"
        else
          "yml"
        end
      end
    end
  end
end
