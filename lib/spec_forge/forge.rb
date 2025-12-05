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
    attr_reader :global_variables
    attr_reader :http_client
    attr_reader :local_variables
    attr_reader :timer

    def initialize(blueprints, verbose: false)
      @blueprints = blueprints
      @display = Display.new(verbose:)
      @timer = Timer.new

      @callbacks = Callbacks.new
      @global_variables = Store.new
      @http_client = HTTP::Client.new(base_url: SpecForge.configuration.base_url)
      @local_variables = Store.new
    end

    def run
      context = Context.new(global_variables:, local_variables:)

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

        forge_end
      end
    end

    private

    def forge_start
      @local_variables.clear
      @global_variables.clear

      # Load from configuration
      SpecForge.configuration.tap do |config|
        config.callbacks.each { |name, block| @callbacks.register_callback(name, &block) }
        config.global_variables.each { |name, value| @global_variables.store(name, value) }
      end

      @timer.start
    end

    def blueprint_start(blueprint)
      # Remove all variables between blueprint runs
      @local_variables.clear

      @display.blueprint_start(blueprint)
    end

    def step_start(step)
      @display.step_start(step)
    end

    def step_action(step)
      # HEY! LISTEN: These read and write to the forge's state
      Debug.new(step).run(self) if step.debug?
      Hooks.new(step).run(self) if step.hooks?
      Call.new(step).run(self) if step.call?
      Request.new(step).run(self) if step.request?
      # Expect.new(step).run(self) if step.expect? # TODO
      #   - Do we need to store variables? (`store`)
    end

    def step_end(step, success:)
      # Drop the request/response data from scope
      @local_variables.remove_all(:request, :response)

      @display.step_end(step, success:)
    end

    def forge_end
      @timer.stop

      @display.forge_end(self)
    end
  end
end
