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

    def initialize(blueprints)
      @blueprints = blueprints
      @store = Store.new
      @global = Store.new
    end

    def run
      # TODO: Copy data from configuration
      @global.clear

      @blueprints.each do |blueprint|
        @store.clear

        # 1. Print step name and description (if provided)
        # 2. Determine what action needs to happen.
        #   - Do we need to trigger debugging? (`debug`)
        #   - Do we need to hook any callbacks (`hook`)
        #   - Do we need to run any callbacks (`call`)
        #   - Do we need to handle HTTP request? (`request`)
        #   - Do we need to create/run tests? (`expect`)
        #   - Do we need to store variables? (`store`)
        blueprint.steps.each do |step|
          # Pre
          print_step_header(step)

          # Actionable
          run_debug_step(step) if step.debug?

          # Post
          # TODO: Clear request/response data so it doesn't leak
        end
      end
    end

    private

    def print_step_header(step)
      line_number = step.source.line_number.to_s.rjust(2, "0")
      name = step.name || "Unnamed step (line #{line_number})"

      message = "[#{step.source.file_name}:#{line_number}] #{name}"
      header = "*" * (100 - message.size)

      puts "#{message} #{header}"
      puts step.description if step.description.present?
      puts ""
    end

    def run_debug_step(step)
      Action::Debug.new(step).run
    end
  end
end
