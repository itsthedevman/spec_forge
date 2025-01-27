module SpecForge
  class CLI
    class Init < Command
      command_name "init"
      syntax "init"
      summary "Initializes directory structure and configuration files at .spec_forge"

      option "-d", "--directory STRING",
        String, "The path where SpecForge should place its files. Defaults to .spec_forge"

      def call
        base_path =
          if (path = options.directory)
            Pathname.new(path)
          else
            SpecForge.root.join(".spec_forge")
          end

        actions.empty_directory "#{base_path}/factories"
        actions.empty_directory "#{base_path}/specs"

        actions.create_file "#{base_path}/config.yml", SpecForge.configuration.to_yaml
      end
    end
  end
end
