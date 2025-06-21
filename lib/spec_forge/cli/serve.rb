# frozen_string_literal: true

module SpecForge
  class CLI
    class Serve < Command
      include Docs::Generate
      #
      # Valid file formats for documentation output
      #
      # Supported formats include YAML variants (yml, yaml) and JSON.
      # Used for validation when users specify the --format option.
      #
      # @api private
      #
      VALID_FORMATS = %w[yml yaml json].freeze

      command_name "serve"
      syntax "serve"
      summary ""
      description ""

      option "--use-cache",
        "Use cached test data if available, otherwise run tests to generate cache"

      option "--format=FORMAT",
        "The file format of the output: yml/yaml or json (default: yml)"

      option "--output=PATH",
        "Custom output path for generated documentation"

      option "--skip-validation",
        "Skip OpenAPI specification validation during generation"

      option "--ui=UI",
        "Documentation interface to use (swagger, redoc) [default: swagger]"

      option "--force",
        "Regenerate documentation even if it already exists"

      option "--port=PORT",
        "Port to serve documentation on [default: 8080]"

      aliases :s

      def call
        server_path = SpecForge.openapi_path.join("server")
        actions.empty_directory(server_path, verbose: false) # spec_forge/openapi/server

        # Generate or copy the spec over
        file_name = generate_or_copy_spec

        # Determine which template file to use
        template_name =
          if options.ui == "redoc"
            "redoc.html.tt"
          else
            "swagger.html.tt"
          end

        # Remove the index if it exists
        index_path = server_path.join("index.html")
        index_path.delete if index_path.exist?

        # Generate index.html
        actions.template(
          template_name,
          index_path,
          context: Proxy.new(spec_url: file_name).call,
          verbose: false
        )

        # And serve it!
        port = options.port || 8080
        server = WEBrick::HTTPServer.new(
          Port: port,
          DocumentRoot: server_path
        )

        puts <<~STRING
          ========================================
          🚀 SpecForge Documentation Server
          ========================================
          Server running at: http://localhost:#{port}
          Press Ctrl+C to stop
          ========================================
        STRING

        trap("INT") { server.shutdown }
        server.start
      end

      private

      def generate_or_copy_spec
        server_path = SpecForge.openapi_path.join("server")

        file_format = determine_file_format
        file_path = determine_output_path(file_format)

        if options.force || !file_path.exist?
          CLI::Docs.new([], options).generate_documentation
        end

        file_name = "openapi.#{file_format}"
        path = server_path.join(file_name)
        path.delete if path.exist?

        actions.copy_file(file_path, path, verbose: false)

        file_name
      end

      #
      # Helper class for passing template variables to Thor templates
      #
      class Proxy < Struct.new(:spec_url)
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
