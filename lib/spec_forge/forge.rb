# frozen_string_literal: true

module SpecForge
  #
  # The main execution engine for running blueprints
  #
  # Forge orchestrates the execution of blueprints by managing the execution
  # context, HTTP client, variable storage, and display output. It processes
  # each step sequentially and tracks statistics across the run.
  #
  class Forge
    class << self
      #
      # Initializes SpecForge by loading the forge_helper and factories
      #
      # @return [Class] self for chaining
      #
      def ignite
        load_forge_helper
        Factory.load_and_register

        # Return for chaining
        self
      end

      #
      # Creates a new Forge instance and runs the given blueprints
      #
      # @param blueprints [Array<Blueprint>] The blueprints to execute
      # @param verbosity_level [Integer] Output verbosity (0-3)
      #
      # @return [void]
      #
      def run(blueprints, verbosity_level: 0)
        new(blueprints, verbosity_level:).run
      end

      #
      # Returns the current execution context for the current thread
      #
      # @return [Context, nil] The current context or nil if not executing
      #
      def context
        Thread.current[:spec_forge_context]
      end

      #
      # Executes a block with a given context
      #
      # @param context [Context] The context to use during execution
      #
      # @yield Block to execute with the context
      #
      # @return [Object] The result of the block
      #
      def with_context(context)
        old_context = Thread.current[:spec_forge_context]
        Thread.current[:spec_forge_context] = context
        yield
      ensure
        Thread.current[:spec_forge_context] = old_context
      end

      private

      def load_forge_helper
        forge_helper = SpecForge.forge_path.join("forge_helper.rb")
        return unless File.exist?(forge_helper)

        require_relative forge_helper

        # Revalidate in case anything was changed
        SpecForge.configuration.validate
      end
    end

    # @return [Array<Blueprint>] The blueprints being executed
    attr_reader :blueprints

    # @return [Callbacks] Callback registry for this forge run
    attr_reader :callbacks

    # @return [Display] Display handler for output formatting
    attr_reader :display

    # @return [Array<Hash>] List of failed expectations
    attr_reader :failures

    # TODO: documentation
    attr_reader :hooks

    # @return [HTTP::Client] HTTP client for making requests
    attr_reader :http_client

    # @return [Runner] RSpec runner for executing expectations
    attr_reader :runner

    # @return [Hash] Statistics about the current run
    attr_reader :stats

    # @return [Timer] Timer for tracking execution duration
    attr_reader :timer

    # @return [Variables] Variable storage for the current run
    attr_reader :variables

    #
    # Creates a new Forge instance with the specified blueprints
    #
    # @param blueprints [Array<Blueprint>] The blueprints to execute
    # @param verbosity_level [Integer] Output verbosity (0-3)
    # @param hooks [Hash] Forge-level event hooks
    #
    # @return [Forge] A new forge instance
    #
    def initialize(blueprints, verbosity_level: 0, hooks: {})
      @blueprints = blueprints
      @callbacks = Callbacks.new
      @display = Display.new(verbosity_level:)
      @failures = []
      @hooks = Step::Call.wrap_hooks(hooks)
      @http_client = HTTP::Client.new
      @runner = Runner.new
      @stats = {}
      @timer = Timer.new
      @variables = Variables.new(static: SpecForge.configuration.global_variables)

      reset_stats
    end

    #
    # Executes all blueprints and their steps
    #
    # @return [void]
    #
    def run
      context = Context.new(variables:)

      Forge.with_context(context) do
        forge_start

        @blueprints.each do |blueprint|
          blueprint_start(blueprint)

          blueprint.steps.each do |step|
            step_start(step)
            step_action(step)
            step_end(step)
          rescue => e
            step_end(step, error: e)
            break
          end

          blueprint_end(blueprint)
        end
      ensure
        forge_end
      end
    end

    private

    def reset_stats
      @stats = {
        blueprints: 0,
        steps: 0,
        passed: 0,
        failed: 0
      }
    end

    def forge_start
      reset_stats

      # Load the callbacks from the configuration
      SpecForge.configuration.callbacks.each { |name, block| @callbacks.register(name, &block) }

      @display.forge_start(self)
      @timer.start

      Hooks.before_forge(self)
    end

    def blueprint_start(blueprint)
      @variables.clear
      @failures.clear

      @display.blueprint_start(blueprint)

      Hooks.before_blueprint(self, blueprint)
    end

    def step_start(step)
      @display.step_start(step)

      Hooks.before_step(self, step)
    end

    def step_action(step)
      # HEY! LISTEN: These read and write to the forge's state
      Call.new(step).run(self) if step.calls?
      Request.new(step).run(self) if step.request?
      Debug.new(step).run(self) if step.debug?
      Expect.new(step).run(self) if step.expects?
      Store.new(step).run(self) if step.store?
    end

    def step_end(step, error: nil)
      @stats[:steps] += 1

      if error.is_a?(Error::ExpectationFailure)
        @failures += error.failed_examples.map { |example| {step:, example:} }
      end

      Hooks.after_step(self, step, error:)

      @display.step_end(self, step, error:)

      # Bubble up only AFTER display has been updated
      raise error if error && !error.is_a?(Error::ExpectationFailure)
    ensure
      # Drop the request/response data from scope
      # Do this after everything is done so variables can be printed out if needed
      @variables.except!(:request, :response)
    end

    def blueprint_end(blueprint)
      @stats[:blueprints] += 1

      @display.blueprint_end(blueprint, success: @failures.empty?)

      Hooks.after_blueprint(self, blueprint)
    end

    def forge_end
      @timer.stop

      @display.forge_end(self)
      Hooks.after_forge(self)

      @display.stats(self)
    end
  end
end
