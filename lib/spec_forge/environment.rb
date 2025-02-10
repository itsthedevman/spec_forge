# frozen_string_literal: true

module SpecForge
  class Environment
    include Singleton

    #
    # Prepares and loads the environment based on the config
    #
    def self.load
      instance.load
    end

    attr_reader :environment, :framework

    # @private
    def initialize
      @environment = SpecForge.config.environment

      @framework =
        if environment.is_a?(String)
          environment
        else
          environment.use
        end
    end

    # @private
    def load
      load_framework
      load_preload
    end

    # @private
    def load_framework
      case framework
      when "rails"
        load_rails
      else
        load_generic
      end
    end

    # @private
    def load_rails
      path = SpecForge.root.join("config", "application")
      if !path.exist?
        warn <<~WARNING.chomp
          SpecForge warning: Config attribute "environment" set to "rails" but Rails environment (config/environment.rb) does not exist.
          Factories or model-dependent features may not function as expected.
            - For non-Rails projects, set your environment's 'models_path' or 'preload' in your config.yml
            - To disable this warning, set 'environment: ""' in your config.yml.
        WARNING

        return
      end

      require path unless defined?(Rails)
    end

    # @private
    def load_generic
      return unless environment.is_a?(Environment)

      models_path = SpecForge.root.join(environment.models_path)
      return if !models_path.exist?

      Dir[models_path.join("**/*.rb")].each { |file| require file }
    end

    # @private
    def load_preload
      return unless environment.is_a?(Environment) && environment.preload?

      path = SpecForge.root.join(environment.preload)
      return if !path.exist?

      require path
    end
  end
end
