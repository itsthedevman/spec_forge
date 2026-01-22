# frozen_string_literal: true

module SpecForge
  class CLI
    #
    # Command for generating OpenAPI documentation from SpecForge tests
    #
    # Runs tests and extracts endpoint data to create OpenAPI specifications.
    # Uses intelligent caching to avoid unnecessary test re-execution when
    # specs haven't changed.
    #
    # @example Generate documentation
    #   spec_forge docs
    #
    # @example Generate with fresh test run
    #   spec_forge docs --fresh
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
      summary "Generate OpenAPI documentation from test results"

      description <<~DESC
        Generate OpenAPI documentation from test results.

        Uses caching to avoid re-running tests unless specs
        have changed. Output format can be YAML or JSON.
      DESC

      example "docs",
        "Generates OpenAPI specifications from your tests using smart caching"

      example "docs --fresh",
        "Forces test re-execution and regenerates OpenAPI specs ignoring cache"

      example "docs --format json",
        "Generates OpenAPI specifications in JSON format instead of YAML"

      example "docs --output ./build/api.yml",
        "Generates OpenAPI specs to a custom file path"

      example "docs --skip-validation",
        "Generates documentation without validating the OpenAPI specification"

      option "--fresh", "Re-run all tests ignoring cache"
      option "--format=FORMAT", "Output format: yml/yaml or json (default: yml)"
      option "--output=PATH", "Full file path for generated documentation"
      option "--skip-validation", "Skip OpenAPI specification validation during generation"

      # TODO: Add verbosity flags for Forge

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
      rescue NoBlueprintsError => e
        puts e.message
      end
    end
  end
end
