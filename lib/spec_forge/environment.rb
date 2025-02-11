# frozen_string_literal: true

module SpecForge
  class Environment
    attr_reader :environment, :framework

    #
    # Creates a new environment loader
    #
    # @param environment [Config::Environment] The environment to load
    #
    def initialize(environment = SpecForge.config.environment)
      @environment = environment
      @framework = environment.use
    end

    #
    # Loads the environment
    #
    def load
      load_framework
      load_preload

      self
    end

    private

    def load_framework
      case framework
      when "rails"
        load_rails
      else
        load_generic
      end
    end

    def load_rails
      path = SpecForge.root.join("config", "environment.rb")

      if File.exist?(path)
        require path
      else
        warn <<~WARNING.chomp
          SpecForge warning: Config attribute "environment" set to "rails" but Rails environment (config/environment.rb) does not exist.
          Factories or model-dependent features may not function as expected.
            - For non-Rails projects, set your environment's 'models_path' or 'preload' in your config.yml
            - To disable this warning, set 'environment: ""' in your config.yml.
        WARNING
      end
    end

    def load_generic
      return unless environment.models_path? && environment.models_path.present?

      models_path = SpecForge.root.join(environment.models_path)
      return if !File.exist?(models_path)

      Dir[models_path.join("**/*.rb")].each { |file| require file }
    end

    def load_preload
      return unless environment.preload? && environment.preload.present?

      path = SpecForge.root.join(environment.preload)
      return if !File.exist?(path)

      require path
    end
  end
end
