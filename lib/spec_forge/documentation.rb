# frozen_string_literal: true

module SpecForge
  module Documentation
    def self.config
      @config ||= begin
        path = SpecForge.docs_path.join("config.yml")
        hash = YAML.safe_load_file(path).deep_symbolize_keys

        Normalizer.normalize_documentation_config!(hash)
      end
    end

    def self.renderer(renderer_class)
      test_data = Documentation::Loader.extract_from_tests
      document = Documentation::Builder.build(**test_data)
      renderer_class.new(document)
    end
  end
end

require_relative "documentation/builder"
require_relative "documentation/document"
require_relative "documentation/loader"
require_relative "documentation/renderers"
