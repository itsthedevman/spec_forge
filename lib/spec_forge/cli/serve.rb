# frozen_string_literal: true

module SpecForge
  class CLI
    #
    # Command for generating and serving API documentation
    #
    # Combines documentation generation with a local web server to provide
    # an easy way to view and interact with generated API documentation.
    # Supports both Swagger UI and Redoc interfaces.
    #
    # @example Start documentation server
    #   spec_forge serve
    #
    # @example Serve with Redoc UI
    #   spec_forge serve --ui redoc
    #
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
      summary "Start a local server to preview your API documentation"
      description <<~DESC
        Generate documentation and start a local preview server.

        Combines docs generation with a web interface. Choose between
        Swagger UI or Redoc for viewing the documentation.
      DESC

      example "serve",
        "Generates docs (if needed) and starts documentation server at localhost:8080"

      example "serve --fresh",
        "Re-runs tests, regenerates docs, and starts the documentation server"

      example "serve --ui redoc",
        "Starts server with Redoc interface instead of Swagger UI"

      example "serve --port 3001",
        "Starts documentation server on port 3001"

      example "serve --fresh --ui redoc --port 3001",
        "Re-runs tests and serves fresh docs with Redoc on custom port"

      # Generation options
      option "--fresh", "Re-run all tests before starting server"
      option "--format=FORMAT", "Output format: yml/yaml or json (default: yml)"
      option "--skip-validation", "Skip OpenAPI specification validation during generation"

      # Server options
      option "--ui=UI", "Documentation interface: swagger or redoc (default: swagger)"
      option "--port=PORT", "Port to serve documentation on (default: 8080)"

      aliases :s

      #
      # Generates documentation and starts a local web server
      #
      # Creates OpenAPI documentation from tests and serves it through a local
      # HTTP server with either Swagger UI or Redoc interface for easy viewing.
      #
      # @return [void]
      #
      def call
        server_path = SpecForge.openapi_path.join("server")
        actions.empty_directory(server_path, verbose: false) # spec_forge/openapi/server

        # Generate and copy the OpenAPI spec file
        file_name = generate_and_copy_openapi_spec

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

      def generate_and_copy_openapi_spec
        server_path = SpecForge.openapi_path.join("server")

        file_path = generate_documentation

        file_name = file_path.basename
        path = server_path.join(file_name)

        # If the file already exists, delete it
        # This ensures we always have the latest spec
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
