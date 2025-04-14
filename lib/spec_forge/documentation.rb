# frozen_string_literal: true

module SpecForge
  module Documentation
    def self.render(renderer_class, use_cache: false, path: nil)
      cache_path = SpecForge.openapi_path.join("generated", ".cache", "loader.yml")

      endpoints =
        if use_cache && File.exist?(cache_path)
          YAML.safe_load_file(cache_path, symbolize_names: true)
        else
          endpoints = Documentation::Loader.extract_from_tests

          # Write out the cache
          File.write(cache_path, endpoints.to_yaml)

          endpoints
        end

      document = Documentation::Builder.document_from_endpoints(endpoints)
      renderer = renderer_class.new(document)
      return renderer unless path

      puts "Writing to #{path.relative_path_from(SpecForge.openapi_path)}"
      renderer.to_file(path)
    end
  end
end

require_relative "documentation/builder"
require_relative "documentation/document"
require_relative "documentation/loader"
require_relative "documentation/renderers"
