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
      @timer.start

      @local_variables.clear
      @global_variables.clear

      load_from_configuration

      @blueprints.each do |blueprint|
        @local_variables.clear

        @display.blueprint_start(blueprint)
        blueprint.steps.each do |step|
          @display.step_start(step)

          # Actionable. These read and write to forge state
          Debug.new(step).run(self) if step.debug?
          Hooks.new(step).run(self) if step.hooks?
          Call.new(step).run(self) if step.call?
          Request.new(step).run(self) if step.request?
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
