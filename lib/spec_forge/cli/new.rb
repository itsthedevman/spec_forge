# frozen_string_literal: true

module SpecForge
  class CLI
    class New < Command
      command_name "new"
      summary "Create a new spec or factory"

      syntax "new <type> <name>"

      example "new spec users",
        "Creates a new spec located at 'spec_forge/specs/users.yml'"

      example "new factory user",
        "Creates a new factory located at 'spec_forge/factories/user.yml'"

      example "generate spec accounts",
        "Uses the generate alias (shorthand 'g') instead of 'new'"

      aliases :generate, :g

      def call
        type = arguments.first.downcase
        name = arguments.second

        # Cleanup
        name.delete_suffix!(".yml") if name.end_with?(".yml")
        name.delete_suffix!(".yaml") if name.end_with?(".yaml")

        case type
        when "spec"
          create_new_spec(name)
        when "factory"
          create_new_factory(name)
        end
      end

      private

      def create_new_spec(name)
        actions.template(
          "new_spec.tt",
          SpecForge.forge_path.join("specs", "#{name}.yml"),
          context: Proxy.new(name).call
        )
      end

      def create_new_factory(name)
        actions.template(
          "new_factory.tt",
          SpecForge.forge_path.join("factories", "#{name}.yml"),
          context: Proxy.new(name).call
        )
      end

      class Proxy
        attr_reader :original_name, :singular_name, :plural_name

        def initialize(name)
          @original_name = name
          @plural_name = name.pluralize
          @singular_name = name.singularize
        end

        def call
          binding
        end
      end
    end
  end
end
