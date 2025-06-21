# frozen_string_literal: true

require_relative "docs/generate"

module SpecForge
  class CLI
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
      summary ""
      description ""

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

      def call
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
