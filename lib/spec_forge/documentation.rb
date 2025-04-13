# frozen_string_literal: true

module SpecForge
  module Documentation
    def self.config
      @config ||= begin
        path = SpecForge.openapi_path.join("config.yml")
        hash = YAML.safe_load_file(path, symbolize_names: true)

        Normalizer.normalize_documentation_config!(hash)
      end
    end

    def self.render(renderer_class, use_cache: false, path: nil)
      cache_path = SpecForge.openapi_path.join("export", ".loader_cache.yml")

      test_data =
        if use_cache && File.exist?(cache_path)
          YAML.safe_load_file(cache_path, symbolize_names: true)
        else
          data = Documentation::Loader.extract_from_tests

          # Write out the cache
          File.write(cache_path, data.deep_stringify_keys.to_yaml)

          data
        end

      document = Documentation::Builder.build(**test_data)
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
