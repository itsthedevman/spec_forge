# frozen_string_literal: true

module SpecForge
  module Documentation
    def self.config
      @config ||= begin
        path = SpecForge.forge_path.join("docs", "config.yml")
        hash = YAML.safe_load_file(path).deep_symbolize_keys

        Normalizer.normalize_documentation_config!(hash)
      end
    end

    def self.generate
      test_data = Documentation::Loader.extract_from_tests
      document = Documentation::Builder.build(**test_data)
    end
  end
end

require_relative "documentation/builder"
require_relative "documentation/document"
require_relative "documentation/loader"
require_relative "documentation/renderers"
