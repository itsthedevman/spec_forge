# frozen_string_literal: true

module SpecForge
  class CLI
    #
    # Command for generating new blueprints or factories from templates
    #
    # Creates workflow blueprints or test data factories with sensible defaults
    # and realistic examples to get you started quickly.
    #
    # @example Creating a new blueprint
    #   spec_forge new blueprint users
    #
    # @example Creating a new factory
    #   spec_forge new factory user
    #
    class New < Command
      command_name "new"
      summary "Create new workflow blueprints or data factories"

      description <<~DESC
        Generate new files from templates with realistic examples.

        Types:
          • blueprint - Creates workflow files with complete CRUD examples
          • factory   - Creates FactoryBot factories for test data

        Blueprints include examples of:
          • Variable storage and interpolation
          • Sequential request workflows
          • Multiple HTTP methods (GET, POST, PATCH, DELETE)
          • Different expectation patterns
          • Response value chaining

        Files are created in the appropriate spec_forge/ subdirectory
        with proper naming conventions and ready-to-run examples.
      DESC

      syntax "new <type> <name>"

      example "new blueprint users",
        "Creates spec_forge/blueprints/users.yml with CRUD examples"

      example "new blueprint auth/login",
        "Creates spec_forge/blueprints/auth/login.yml in subdirectory"

      example "new factory user",
        "Creates spec_forge/factories/user.yml"

      aliases :generate, :g, :n

      #
      # Creates a new blueprint or factory file from templates
      #
      # @return [void]
      #
      def call
        type = arguments.first&.downcase
        name = arguments.second

        if type.nil? || name.nil?
          puts "Error: Both type and name are required."
          puts "Usage: spec_forge new <type> <name>"
          puts ""
          puts "Examples:"
          puts "  spec_forge new blueprint users"
          puts "  spec_forge new factory user"
          exit(1)
        end

        # Clean up the name
        name = normalize_name(name)

        case type
        when "blueprint", "blueprints", "spec", "specs"
          create_new_blueprint(name)
        when "factory", "factories"
          create_new_factory(name)
        else
          puts "Error: Unknown type '#{type}'"
          puts "Valid types: blueprint, factory"
          exit(1)
        end
      end

      private

      #
      # Normalizes the name by removing extensions
      #
      # @param name [String] The raw name from user input
      #
      # @return [String] Cleaned name without extensions
      #
      def normalize_name(name)
        name.delete_suffix(".yml").delete_suffix(".yaml")
      end

      #
      # Creates a new blueprint file with workflow template
      #
      # @param name [String] The blueprint name
      #
      # @return [void]
      #
      def create_new_blueprint(name)
        actions.template(
          "new_blueprint.yml.tt",
          SpecForge.forge_path.join("blueprints", "#{name}.yml"),
          context: Proxy.new(name).call
        )
      end

      #
      # Creates a new factory file with template
      #
      # @param name [String] The factory name
      #
      # @return [void]
      #
      def create_new_factory(name)
        actions.template(
          "new_factory.yml.tt",
          SpecForge.forge_path.join("factories", "#{name}.yml"),
          context: Proxy.new(name).call
        )
      end

      #
      # Helper class for passing template variables to Thor templates
      #
      # @example Creating a proxy with a name
      #   proxy = Proxy.new("user")
      #   proxy.singular_name # => "user"
      #   proxy.plural_name # => "users"
      #
      class Proxy
        #
        # The original name passed to the command
        #
        # @return [String]
        #
        attr_reader :original_name

        #
        # The singular form of the name
        #
        # @return [String]
        #
        attr_reader :singular_name

        #
        # The plural form of the name
        #
        # @return [String]
        #
        attr_reader :plural_name

        #
        # Creates a new Proxy with the specified name
        #
        # @param name [String] The resource name to pluralize/singularize
        #
        # @return [Proxy] A new proxy instance
        #
        def initialize(name)
          @original_name = name
          @plural_name = name.pluralize
          @singular_name = name.singularize
        end

        #
        # Returns a binding for use in templates
        #
        # @return [Binding] A binding containing template variables
        #
        def call
          binding
        end
      end
    end
  end
end
