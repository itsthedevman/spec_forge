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

    attr_reader :blueprints, :local_variables, :global_variables, :callbacks, :display, :timer

    def initialize(blueprints, verbose: false)
      @blueprints = blueprints
      @display = Display.new(verbose:)
      @timer = Timer.new

      @local_variables = Store.new
      @global_variables = Store.new
      @callbacks = Callbacks.new
    end

    def run
      @timer.start

      @local_variables.clear
      @global_variables.clear

      load_from_configuration

      @blueprints.each do |blueprint|
        @display.blueprint_start(blueprint)

        @local_variables.clear

        blueprint.steps.each do |step|
          @display.step_start(step)

          # Actionable
          Debug.new(step).run(self) if step.debug?
          Hooks.new(step).run(self) if step.hooks?
          Call.new(step).run(self) if step.call?
          #   - Do we need to handle HTTP request? (`request`)
          #   - Do we need to create/run tests? (`expect`)
          #   - Do we need to store variables? (`store`)

          # Post
          # TODO: Clear request/response data so it doesn't leak
          @display.step_end(step, success: true)
        rescue => e
          @display.step_end(step, success: false)
          raise e
        end
      end

      @timer.stop
      @display.forge_end(self)
    end

    private

    def load_from_configuration
      SpecForge.configuration.tap do |config|
        config.callbacks.each { |name, block| @callbacks.register_callback(name, &block) }
        config.global_variables.each { |name, value| @global_variables.store(name, value) }
      end
    end
  end
end
