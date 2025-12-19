# frozen_string_literal: true

module SpecForge
  class Forge
    class << self
      def ignite
        load_forge_helper
        Factory.load_and_register

        # Return for chaining
        self
      end

      def run(blueprints)
        new(blueprints).run
      end

      def context
        Thread.current[:spec_forge_context]
      end

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

    attr_predicate :verbose

    attr_reader :blueprints
    attr_reader :callbacks
    attr_reader :display
    attr_reader :http_client
    attr_reader :runner
    attr_reader :timer
    attr_reader :variables

    def initialize(blueprints, verbose: false)
      @blueprints = blueprints
      @callbacks = Callbacks.new
      @display = Display.new(verbose:)
      @http_client = HTTP::Client.new(base_url: SpecForge.configuration.base_url)
      @runner = Runner.new
      @timer = Timer.new
      @variables = Variables.new(static: SpecForge.configuration.global_variables)
    end

    def run
      context = Context.new(variables:)

      Forge.with_context(context) do
        forge_start

        @blueprints.each do |blueprint|
          blueprint_start(blueprint)

          blueprint.steps.each do |step|
            step_start(step)
            step_action(step)
            step_end(step, success: true)
          rescue => e
            step_end(step, success: false)
            raise e
          end
        end

        forge_end(success: true)
      end
    rescue => e
      handle_error(e)
      forge_end(success: false)
    end

    private

    def forge_start
      # Load the callbacks from the configuration
      SpecForge.configuration.callbacks.each { |name, block| @callbacks.register(name, &block) }

      @timer.start
    end

    def blueprint_start(blueprint)
      @variables.clear

      @display.blueprint_start(blueprint)
    end

    def step_start(step)
      @display.step_start(step)
    end

    def step_action(step)
      # HEY! LISTEN: These read and write to the forge's state
      Debug.new(step).run(self) if step.debug?
      Call.new(step).run(self) if step.call?
      Request.new(step).run(self) if step.request?
      Expect.new(step).run(self) if step.expect?
      Store.new(step).run(self) if step.store?
    end

    def step_end(step, success:)
      # Drop the request/response data from scope
      @variables.except!(:request, :response)

      @display.step_end(step, success:)
    end

    def forge_end(success:)
      @timer.stop

      @display.forge_end(self, success:)
    end

    def handle_error(error)
      raise error unless error.is_a?(Error::ExpectationFailure)

      example = error.failed_example

      display.error(example[:exception][:message], indent: 1)
    end
  end
end
