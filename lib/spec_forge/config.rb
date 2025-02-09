# frozen_string_literal: true

module SpecForge
  class Config < Struct.new(:base_url, :authorization, :factories, :environment)
    class Authorization < Struct.new(:header, :value)
      attr_predicate :header, :value
    end

    class Factories < Struct.new(:paths, :auto_discover)
      attr_predicate :paths, :auto_discover
    end

    class Environment < Struct.new(:use, :preload, :models_path)
      attr_predicate :use, :preload, :models_path
    end

    ############################################################################

    def initialize
      config = Normalizer.default_config.deep_merge(load_from_file)
      normalized = Normalizer.normalize_config!(config)

      super(
        base_url: normalized.delete(:base_url),
        authorization: transform_authorization(normalized),
        factories: transform_factories(normalized),
        environment: transform_environment(normalized)
      )
    end

    private

    def load_from_file
      path = SpecForge.forge.join("config.yml")
      return unless File.exist?(path)

      erb = ERB.new(File.read(path)).result
      YAML.safe_load(erb, aliases: true, symbolize_names: true)
    end

    def transform_authorization(hash)
      # The intention for authorization hash is to support different authorization schemes
      # authorization: {default: {}, admin: {}, dev: {}}
      # But I won't know exactly what will be defined - `to_struct` will handle that.
      hash[:authorization].transform_values { |v| Authorization.new(**v) }.to_struct
    end

    def transform_factories(hash)
      Factories.new(**hash[:factories])
    end

    def transform_environment(hash)
      environment = hash[:environment]

      if environment.is_a?(Hash)
        Environment.new(**environment)
      else
        environment
      end
    end
  end
end
