# frozen_string_literal: true

module SpecForge
  #
  # Holds configuration options for SpecForge
  #
  # Configuration is typically set in forge_helper.rb using the configure block.
  # It controls base URL, global variables, factory settings, callbacks, and more.
  #
  # @example Basic configuration
  #   SpecForge.configure do |config|
  #     config.base_url = "http://localhost:3000"
  #     config.global_variables = {api_version: "v1"}
  #   end
  #
  class Configuration
    #
    # Configuration for FactoryBot factory loading
    #
    class Factories < Struct.new(:auto_discover, :paths)
      # @return [Boolean] Whether auto-discovery is enabled
      attr_predicate :auto_discover

      # @return [Array<String>] Factory file paths
      attr_predicate :paths

      def initialize(auto_discover: true, paths: []) = super
    end

    # @return [String] Base URL for HTTP requests
    attr_accessor :base_url

    # @return [Hash] Global variables available to all blueprints
    attr_accessor :global_variables

    # @return [Factories] Factory configuration
    attr_reader :factories

    # @return [Proc, nil] Debug handler proc
    attr_reader :on_debug_proc

    # @return [Hash{Symbol => Proc}] Registered callbacks
    attr_reader :callbacks

    #
    # Creates a new Configuration with default values
    #
    # @return [Configuration] A new configuration instance
    #
    def initialize
      # Validated
      @base_url = "http://localhost:3000"
      @factories = Factories.new
      @global_variables = {}

      # Internal
      @on_debug_proc = nil
      @callbacks = {}
    end

    #
    # Validates the configuration and normalizes values
    #
    # @return [Configuration] self
    #
    # @raise [Error::InvalidStructureError] If configuration is invalid
    #
    def validate
      output = Normalizer.normalize!(
        {
          base_url: @base_url,
          factories: @factories.to_h,
          global_variables: @global_variables
        },
        using: :configuration
      )

      # In case any value was set to `nil`
      @global_variables = output[:global_variables] if @global_variables.blank?
      @global_variables.symbolize_keys!

      self
    end

    #
    # Sets a debug handler block to be called when a step has debug: true
    #
    # @yield [context] Block called when debug is triggered
    # @yieldparam context [Forge::Context] The current execution context
    #
    # @example
    #   config.on_debug { binding.pry }
    #
    def on_debug(&block)
      @on_debug_proc = block
    end

    #
    # Returns RSpec's configuration for customization
    #
    # @return [RSpec::Core::Configuration] RSpec configuration
    #
    def rspec
      RSpec.configuration
    end

    #
    # Registers a callback that can be invoked from blueprints using call:
    #
    # @param name [String, Symbol] The callback name to register
    #
    # @yield [context, *args] Block to execute when callback is called
    # @yieldparam context [Forge::Context] The current execution context
    #
    # @example Simple callback
    #   config.register_callback("seed_data") do |context|
    #     User.create!(name: "Test")
    #   end
    #
    # @example Callback with arguments
    #   config.register_callback("create_users") do |context, count:|
    #     count.times { User.create! }
    #   end
    #
    def register_callback(name, &block)
      @callbacks[name.to_sym] = block
    end
  end
end
