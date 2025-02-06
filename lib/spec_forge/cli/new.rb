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
        actions.create_file(
          SpecForge.forge.join("specs", "#{name}.yml"),
          generate_spec(name)
        )
      end

      def create_new_factory(name)
        actions.create_file(
          SpecForge.forge.join("factories", "#{name}.yml"),
          generate_factory(name)
        )
      end

      def generate_spec(name)
        plural_name = name.pluralize
        singular_name = name.singularize

        base_spec = {url: ""}
        base_constraint = {expect: {status: 200}}

        hash = {
          ##################################################
          "index_#{plural_name}" => base_spec.merge(
            url: "/#{plural_name}",
            expectations: [base_constraint]
          ),
          ##################################################
          "show_#{singular_name}" => base_spec.merge(
            url: "/#{plural_name}/{id}",
            expectations: [
              base_constraint.merge(expect: {status: 404}),
              base_constraint.deep_merge(
                query: {id: 1},
                expect: {
                  json: {
                    name: "kind_of.string",
                    email: /\w+@example\.com/i
                  }
                }
              )
            ]
          ),
          ##################################################
          "create_#{singular_name}" => base_spec.merge(
            url: "/#{plural_name}",
            method: "post",
            expectations: [
              base_constraint.merge(expect: {status: 400}),
              base_constraint.deep_merge(
                variables: {
                  name: "faker.name.name",
                  role: "user"
                },
                body: {name: "variables.name"},
                expect: {
                  json: {name: "variables.name", role: "variables.role"}
                }
              )
            ]
          ),
          ##################################################
          "update_#{singular_name}" => base_spec.merge(
            url: "/#{plural_name}/{id}",
            method: "patch",
            query: {id: 1},
            variables: {
              number: {
                "faker.number.between" => {from: 100_000, to: 999_999}
              }
            },
            expectations: [
              base_constraint.deep_merge(
                body: {number: "variables.number"},
                expect: {
                  json: {name: "kind_of.string", number: "kind_of.integer"}
                }
              )
            ]
          ),
          ##################################################
          "destroy_#{singular_name}" => base_spec.merge(
            url: "/#{plural_name}/{id}",
            method: "delete",
            query: {id: 1},
            expectations: [
              base_constraint
            ]
          )
        }

        generate_yaml(hash)
      end

      def generate_factory(name)
        singular_name = name.singularize

        hash = {
          singular_name => {
            class: singular_name.titleize,
            attributes: {
              attribute: "value"
            }
          }
        }

        generate_yaml(hash)
      end

      def generate_yaml(hash)
        result = hash.deep_stringify_keys.join_map("\n") do |key, value|
          {key => value}.to_yaml
            .sub!("---\n", "")
            .gsub("!ruby/regexp ", "")
        end

        result.delete!("\"")
        result
      end
    end
  end
end
