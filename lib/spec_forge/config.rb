# frozen_string_literal: true

module SpecForge
  class Config < Data.define(:base_url, :authorization, :factories)
    include Singleton

    def initialize
      config = Normalizer.default_config.deep_merge(load_from_file)
      normalized = Normalizer.normalize_config!(config)

      super(**normalized)
    end

    private

    def load_from_file
      path = SpecForge.forge.join("config.yml")
      return unless File.exist?(path)

      erb = ERB.new(File.read(path)).result
      YAML.safe_load(erb, aliases: true, symbolize_names: true)
    end
  end
end
