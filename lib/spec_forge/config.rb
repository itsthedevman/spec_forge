# frozen_string_literal: true

module SpecForge
  class Config
    include Singleton

    attr_reader :base_url, :authorization

    def initialize
      load_defaults
      load_from_file
    end

    private

    def load_from_hash(hash)
      @base_url = hash[:base_url]
      @authorization = hash[:authorization]
    end

    def load_defaults
      defaults = Normalizer.default_config
      load_from_hash(defaults)
    end

    def load_from_file
      path = SpecForge.forge.join("config.yml")
      return unless File.exist?(path)

      erb = ERB.new(File.read(path)).result
      hash = YAML.safe_load(erb, aliases: true, symbolize_names: true)
      load_from_hash(hash)
    end
  end
end
