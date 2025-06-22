# frozen_string_literal: true

require_relative "docs/generate"

module SpecForge
  class CLI
    #
    # Command for generating OpenAPI documentation from SpecForge tests
    #
    # This is the primary SpecForge workflow - it runs your tests and generates
    # OpenAPI documentation, making your tests serve as living API documentation.
    #
    # @example Generate documentation
    #   spec_forge docs
    #
    # @example Generate with caching
    #   spec_forge docs --use-cache
    #
    class Docs < Command
      include Docs::Generate

      #
      # Valid file formats for documentation output
      #
      # Supported formats include YAML variants (yml, yaml) and JSON.
      # Used for validation when users specify the --format option.
      #
      # @api private
      #
      VALID_FORMATS = %w[yml yaml json].freeze

      command_name "docs"
      syntax "docs"
      summary "Generate OpenAPI documentation from your tests"
      description "Runs your SpecForge tests and generates OpenAPI documentation. This is the primary workflow for creating API documentation through testing."

      example "docs generate",
        "Generates OpenAPI documentation from all tests"

      example "docs --use-cache",
        "Uses cached test data if available, otherwise runs tests first"

      example "docs --format=json",
        "Generates documentation in JSON format instead of YAML"

      example "docs --skip-validation",
        "Generates documentation without validating the OpenAPI specification"

      option "--use-cache",
        "Use cached test data if available, otherwise run tests to generate cache"

      option "--format=FORMAT",
        "The file format of the output: yml/yaml or json (default: yml)"

      option "--output=PATH",
        "Custom output path for generated documentation"

      option "--skip-validation",
        "Skip OpenAPI specification validation during generation"

      #
      # Generates OpenAPI documentation from tests
      #
      # Runs all SpecForge tests and creates OpenAPI specifications from the
      # successful test results. This is the main entry point for the docs workflow.
      #
      # @return [void]
      #
      def call
        # spec_forge/openapi/generated
        generated_path = SpecForge.openapi_path.join("generated")
        actions.empty_directory(generated_path, verbose: false)
        actions.empty_directory(generated_path.join(".cache"), verbose: false)

        file_path = generate_documentation

        puts <<~STRING

          ========================================
          🎉 Success!
          ========================================

          Your OpenAPI specification is valid and ready to use.
          Output written to: #{file_path.relative_path_from(SpecForge.forge_path)}
        STRING
      end
    end
  end
end
