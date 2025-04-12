# frozen_string_literal: true

module SpecForge
  class CLI
    class Docs < Command
      command_name "docs"
      syntax "docs <action>"
      summary "TODO"

      option "--use-cache", "Use cached test data instead of running tests again"

      def call
        case (action = arguments.first)
        when "generate"
          renderer_class = Documentation::Renderers::OpenAPI["3.0"]

          Documentation.render(
            renderer_class,
            path: SpecForge.docs_path.join("export", "openapi.json"),
            use_cache: options.use_cache
          )
        when "serve"
          nil
        else
          raise ArgumentError, "Unexpected action #{action&.in_quotes}. Expected \"generate\" or \"serve\""
        end
      end
    end
  end
end
