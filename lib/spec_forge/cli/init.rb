# frozen_string_literal: true

module SpecForge
  class CLI
    class Init < Command
      command_name "init"
      syntax "init"
      summary "Initializes directory structure and configuration files at .spec_forge"

      option "-d", "--directory STRING",
        String, "The path where SpecForge should place its files. Defaults to .spec_forge"

      def call
        actions.empty_directory "#{base_path}/factories"
        actions.empty_directory "#{base_path}/specs"

        config_example = load_initializer_template

        if defined?(Rails)
          actions.create_file(
            Rails.root.join("config", "initializers", "spec_forge.rb"),
            config_example
          )
        else
          puts <<~STRING.chomp
            Important: You will need to call this code somewhere in your application startup logic

            #{config_example}
          STRING
        end
      end

      private

      def base_path
        @base_path ||= if (path = options.directory)
          path
        else
          CONFIG_ATTRIBUTES[:path][:default]
        end
      end

      def configurations
        config = SpecForge.configure do |config|
          config.path = base_path
        end.to_h

        config.each do |key, value|
          metadata = CONFIG_ATTRIBUTES[key]

          description = metadata[:description]
          raise "Missing description for \"#{key}\" config attribute" if description.blank?

          # Add the default
          if metadata.key?(:default)
            description += "\n  # Defaults to #{metadata[:default].inspect}"
          end

          config[key] = {description:, value:}
        end

        config
      end

      def load_initializer_template
        ERB.new(
          File.read(SpecForge.root.join("lib", "templates", "initializer.tt")),
          trim_mode: "-"
        ).result(binding)
      end
    end
  end
end
