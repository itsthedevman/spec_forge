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

    attr_reader :blueprints, :local_variables, :global_variables, :callbacks

    def initialize(blueprints)
      @blueprints = blueprints
      @local_variables = Store.new
      @global_variables = Store.new
      @callbacks = Callbacks.new
    end

    def run
      @local_variables.clear
      @global_variables.clear

      load_from_configuration

      @blueprints.each do |blueprint|
        @local_variables.clear

        #   - Do we need to handle HTTP request? (`request`)
        #   - Do we need to create/run tests? (`expect`)
        #   - Do we need to store variables? (`store`)
        blueprint.steps.each do |step|
          # Pre
          print_step_header(step)

          # Actionable
          Debug.new(step).run(self) if step.debug?
          Hooks.new(step).run(self) if step.hooks?
          Call.new(step).run(self) if step.call?

          # Post
          # TODO: Clear request/response data so it doesn't leak
          puts ""
        end
      end
    end

    private

    def load_from_configuration
      SpecForge.configuration.tap do |config|
        config.callbacks.each { |name, block| @callbacks.register_callback(name, &block) }
        config.global_variables.each { |name, value| @global_variables.store(name, value) }
      end
    end

    def print_step_header(step)
      line_number = step.source.line_number.to_s.rjust(2, "0")

      message = "[#{step.source.file_name}:#{line_number}] #{step.name}".strip
      header = "*" * (120 - message.size)

      puts "#{message} #{header}"
      puts step.description if step.description.present?
    end
  end
end
