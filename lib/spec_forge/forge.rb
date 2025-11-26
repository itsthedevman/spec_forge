# frozen_string_literal: true

module SpecForge
  class Forge
    def self.from_loader(loader)
      new(loader.blueprints)
    end

    def initialize(blueprints)
      @blueprints
    end

    def run
    end

    private

    def load_forge_helper
      forge_helper = SpecForge.forge_path.join("forge_helper.rb")
      require_relative forge_helper if File.exist?(forge_helper)

      # Validate in case anything was changed
      SpecForge.configuration.validate
    end
  end
end
