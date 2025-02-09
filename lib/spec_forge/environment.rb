# frozen_string_literal: true

module SpecForge
  class Environment
    include Singleton

    def self.load
      instance.load
    end

    attr_reader :environment, :framework

    def initialize
      @environment = SpecForge.config.environment

      @framework =
        if environment.is_a?(String)
          environment
        else
          environment.use
        end
    end

    def load
      load_framework
      load_preload
    end

    def load_framework
      case framework
      when "rails"
        load_rails
      else
        load_generic
      end
    end

    def load_rails
      path = SpecForge.root.join("config", "application")
      if !path.exist?
        warn <<~WARNING.chomp
          SpecForge warning: Config attribute "environment" set to "rails" but Rails environment (config/environment.rb) does not exist.
            - Factories or model-dependent features may not function as expected.
            - For non-Rails projects, use 'environment: { models_path: "lib/models" }' to load your models.
            - To disable this warning, set 'environment: ""' in your config.yml.
        WARNING

        return
      end

      require path unless defined?(Rails)
    end

    def load_generic
      return unless environment.is_a?(Environment)

      models_path = SpecForge.root.join(environment.models_path)
      return if !models_path.exist?

      Dir[models_path.join("**/*.rb")].each { |file| require file }
    end

    def load_preload
      return unless environment.is_a?(Environment) && environment.preload?

      path = SpecForge.root.join(environment.preload)
      return if !path.exist?

      require path
    end
  end
end
