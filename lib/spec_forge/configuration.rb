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
      @events = {
        before_forge: [],
        before_blueprint: [],
        before_step: [],
        after_step: [],
        after_blueprint: [],
        after_forge: []
      }
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

    #
    # Removes a registered callback and detaches it from all lifecycle events
    #
    # @param name [String, Symbol] The callback name to remove
    #
    # @return [Proc, nil] The removed callback proc, or nil if not found
    #
    # @example Remove a callback
    #   config.register_callback(:my_hook) { |context| puts "hook" }
    #   config.before(:step, :my_hook)
    #   config.deregister_callback(:my_hook)  # Removes from callbacks and events
    #
    def deregister_callback(name)
      name = name.to_sym
      callback = @callbacks.delete(name)

      @events.each_value { |a| a.delete(callback) }

      callback
    end

    #
    # Attaches a callback to a before lifecycle event
    #
    # Global hooks run for all blueprints and execute in registration order.
    # Can either reference a pre-registered callback by name, or accept a block
    # to register and attach a callback in one step (like RSpec's before hooks).
    #
    # @param event [Symbol] The lifecycle event (:forge, :blueprint, or :step)
    # @param callback_name [String, Symbol, nil] The name of a registered callback
    #   (optional if block is provided)
    #
    # @yield [context] Block to execute (registers callback automatically)
    # @yieldparam context [Forge::Context] The current execution context
    #
    # @return [String, Symbol] The callback name (auto-generated if block provided)
    #
    # @raise [ArgumentError] If the event is invalid
    # @raise [ArgumentError] If the callback is not registered (when using name)
    #
    # @example Attach a pre-registered callback
    #   config.register_callback(:setup) { |context| Database.seed }
    #   config.before(:forge, :setup)
    #
    # @example Register and attach with a block (like RSpec)
    #   config.before(:step) { |context| Logger.info("Starting step") }
    #   config.before(:blueprint) { |context| Database.clean }
    #
    # @example Store the callback name for later deregistration
    #   callback_name = config.before(:step) { |context| puts "hook" }
    #   config.deregister_callback(callback_name)
    #
    def before(event, callback_name = nil, &block)
      if block
        callback_name = "__sf_cb_#{SecureRandom.uuid.tr("-", "")}"
        register_callback(callback_name, &block)
      end

      add_event("before", event, callback_name)

      callback_name
    end

    #
    # Attaches a callback to an after lifecycle event
    #
    # Global hooks run for all blueprints and execute in registration order.
    # Can either reference a pre-registered callback by name, or accept a block
    # to register and attach a callback in one step (like RSpec's after hooks).
    #
    # @param event [Symbol] The lifecycle event (:forge, :blueprint, or :step)
    # @param callback_name [String, Symbol, nil] The name of a registered callback
    #   (optional if block is provided)
    #
    # @yield [context] Block to execute (registers callback automatically)
    # @yieldparam context [Forge::Context] The current execution context
    #
    # @return [String, Symbol] The callback name (auto-generated if block provided)
    #
    # @raise [ArgumentError] If the event is invalid
    # @raise [ArgumentError] If the callback is not registered (when using name)
    #
    # @example Attach a pre-registered callback
    #   config.register_callback(:cleanup) { |context| Database.clean }
    #   config.after(:forge, :cleanup)
    #
    # @example Register and attach with a block (like RSpec)
    #   config.after(:step) { |context| Logger.info("Step complete") }
    #   config.after(:blueprint) { |context| Database.rollback }
    #
    # @example Store the callback name for later deregistration
    #   callback_name = config.after(:step) { |context| puts "done" }
    #   config.deregister_callback(callback_name)
    #
    def after(event, callback_name = nil, &block)
      if block
        callback_name = "__sf_cb_#{SecureRandom.uuid.tr("-", "")}"
        register_callback(callback_name, &block)
      end

      add_event("after", event, callback_name)

      callback_name
    end

    private

    def add_event(timing, event, callback_name)
      event = :"#{timing}_#{event}"
      callback_name = callback_name.to_sym

      if !@events.key?(event)
        keys = @events.keys.select { |k| k.to_s.start_with?(timing) }.map(&:in_quotes)
        raise ArgumentError, "Invalid event #{event.in_quotes}. Expected one of #{keys.to_or_sentence}"
      end

      if !@callbacks[callback_name]
        keys = @callbacks.keys.map(&:in_quotes)
        raise ArgumentError, "Invalid callback #{callback_name.in_quotes}. Expected one of #{keys.to_or_sentence}"
      end

      @events[event] << @callbacks[callback_name]
    end
  end
end
