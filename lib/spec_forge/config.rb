# frozen_string_literal: true

module SpecForge
  class Config < Struct.new(:base_url, :authorization)
    include Singleton

    def initialize
      load_defaults
      load_from_file
    end

    private

    def load_from_hash(hash)
      if (base_url = hash[:base_url]) && base_url.present?
        self.base_url = base_url
      end

      if (authorization = hash[:authorization]) && authorization.present?
        self.authorization = authorization
      end
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
