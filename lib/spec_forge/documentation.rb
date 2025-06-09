# frozen_string_literal: true

module SpecForge
  #
  # API documentation generation functionality
  #
  # This module provides tools for extracting API documentation from SpecForge
  # test files and generating various output formats like OpenAPI specifications.
  # It handles the complete pipeline from test execution to documentation rendering.
  #
  # @example Generating OpenAPI documentation
  #   # From CLI
  #   spec_forge docs generate
  #
  #   # Programmatically
  #   document = Documentation::Loader.load_document
  #   spec = Documentation::Generators::OpenAPI["3.0"].new(document).generate
  #
  module Documentation
  end
end

require_relative "documentation/builder"
require_relative "documentation/document"
require_relative "documentation/loader"
require_relative "documentation/openapi"
require_relative "documentation/generators"
