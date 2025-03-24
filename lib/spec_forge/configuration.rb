# frozen_string_literal: true

module SpecForge
  #
  # Configuration container for SpecForge settings
  # Defines default values and validation for all configuration options
  #
  class Configuration < Struct.new(:base_url, :headers, :query, :factories, :on_debug)
    #
    # Manages factory configuration settings
    # Controls auto-discovery behavior and custom factory paths
    #
    # @example
    #   config.factories.auto_discover = false
    #   config.factories.paths += ["lib/factories"]
    #
    class Factories < Struct.new(:auto_discover, :paths)
      #
      # Creates reader methods that return boolean values
      # Allows for checking configuration with predicate methods
      #
      attr_predicate :auto_discover, :paths

      #
      # Initializes a new Factories configuration
      # Sets default values for auto-discovery and paths
      #
      # @param auto_discover [Boolean] Whether to auto-discover factories (default: true)
      # @param paths [Array<String>] Additional paths to look for factories (default: [])
      #
      # @return [Factories] A new factories configuration instance
      #
      def initialize(auto_discover: true, paths: []) = super
    end

    #
    # Initializes a new Configuration with default values
    # Sets up the configuration structure including factory settings and debug proxy
    #
    # @return [Configuration] A new configuration instance with defaults
    #
    def initialize
      config = Normalizer.default_configuration

      config[:base_url] = "http://localhost:3000"
      config[:factories] = Factories.new
      config[:on_debug] = Runner::DebugProxy.default

      super(**config)
    end

    #
    # Validates the configuration and applies normalization
    # Ensures all required fields have values and applies defaults when needed
    #
    # @return [self] Returns self for method chaining
    #
    # @api private
    #
    def validate
      output = Normalizer.normalize_configuration!(to_h)

      # In case any value was set to `nil`
      self.base_url = output[:base_url] if base_url.blank?
      self.query = output[:query] if query.blank?
      self.headers = output[:headers] if headers.blank?

      self
    end

    #
    # Recursively converts the configuration to a hash representation
    #
    # @return [Hash] Hash representation of the configuration
    #
    def to_h
      hash = super
      hash[:factories] = hash[:factories].to_h
      hash
    end

    #
    # Returns the RSpec configuration object
    # Provides access to RSpec's internal configuration for test customization
    #
    # @return [RSpec::Core::Configuration] RSpec's configuration object
    #
    # @example Setting formatter options
    #   SpecForge.configure do |config|
    #     config.specs.formatter = :documentation
    #   end
    #
    def specs
      RSpec.configuration
    end

    alias_method :rspec, :specs

    #
    # Registers a callback for a specific test lifecycle event
    # Allows custom code execution at specific points during test execution
    #
    # @param name [Symbol, String] The callback point to register for
    #   (:before_file, :after_expectation, etc.)
    # @yield A block to execute when the callback is triggered
    # @yieldparam context [Object] An object containing context-specific state data, depending
    #   on which hook the callback is triggered from.
    #
    # @return [Proc] The registered callback
    #
    # @example Registering a custom debug handler
    #   SpecForge.configure do |config|
    #     config.register_callback(:on_debug) { binding.pry }
    #   end
    #
    # @example Cleaning database after each test
    #   SpecForge.configure do |config|
    #     config.register_callback(:after_expectation) do
    #       DatabaseCleaner.clean
    #     end
    #   end
    #
    def register_callback(name, &)
      Callbacks.register(name, &)
    end

    alias_method :define_callback, :register_callback
    alias_method :callback, :register_callback
  end
end
