module SpecForge
  class CLI
    class Init < Command
      name "init"
      syntax "init"
      summary "Initializes directory structure and configuration files at .spec_forge"

      def call
        # actions.create_file ".spec_forge/config.yml", "testing: true"
      end
    end
  end
end
