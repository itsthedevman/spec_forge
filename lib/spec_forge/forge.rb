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
    end

    def run
      # TODO: Figure out what's next
    end
  end
end
