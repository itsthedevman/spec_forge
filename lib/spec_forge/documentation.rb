# frozen_string_literal: true

module SpecForge
  #
  # Provides functionality for generating API documentation from SpecForge tests
  #
  # This module serves as the entry point for documentation generation, with methods
  # to extract test data, transform it into a document structure, and render it
  # using various output formats like OpenAPI.
  #
  # @example Generating OpenAPI documentation
  #   SpecForge::Documentation.render(
  #     SpecForge::Documentation::Renderers::OpenAPI["3.0"],
  #     path: "openapi.yml"
  #   )
  #
  module Documentation
    #
    # Renders documentation using the specified renderer
    #
    # Extracts test data (either from cache or by running tests), builds
    # a document structure, and renders it using the provided renderer.
    # Optionally writes the output to a file.
    #
    # @param renderer_class [Class] The renderer class to use
    # @param use_cache [Boolean] Whether to use cached test data instead of running tests
    # @param path [String, Pathname] Optional file path to write the output to
    # @param format [String] The format to render.
    #
    # @return [Renderers::Base] The renderer instance with results
    #
    def self.render(renderer_class, use_cache: false, path: nil, file_format: nil)
      cache_path = SpecForge.openapi_path.join("generated", ".cache", "loader.yml")

      endpoints =
        if use_cache && File.exist?(cache_path)
          YAML.safe_load_file(cache_path, symbolize_names: true)
        else
          endpoints = Documentation::Loader.extract_from_tests

          # Write out the cache
          File.write(cache_path, endpoints.to_yaml(stringify_names: true))

          endpoints
        end

      document = Documentation::Builder.document_from_endpoints(endpoints)
      renderer = renderer_class.new(document)
      return renderer unless path

      renderer.to_file(path, file_format:)

      puts "==============================================="
      puts "Finished!"
      puts ""
      puts "Wrote output to #{path.relative_path_from(SpecForge.openapi_path)}"
      puts ""

      renderer
    end
  end
end

require_relative "documentation/builder"
require_relative "documentation/document"
require_relative "documentation/loader"
require_relative "documentation/openapi"
require_relative "documentation/renderers"
