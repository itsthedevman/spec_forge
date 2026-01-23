# frozen_string_literal: true

module SpecForge
  module Documentation
    #
    # Builds API documentation by running blueprints and extracting endpoint data
    #
    # The Builder orchestrates the documentation generation process by:
    # 1. Loading and running blueprint test files
    # 2. Capturing request/response data from successful test executions
    # 3. Compiling the raw data into a structured Document
    #
    # It supports caching to avoid re-running tests when blueprints haven't changed.
    #
    # @example Creating a document from blueprints
    #   document = Builder.create_document!(paths: "spec/blueprints/api.yml")
    #
    # @example Using the builder directly for raw endpoint data
    #   builder = Builder.new(paths: "spec/blueprints/api.yml")
    #   endpoints = builder.endpoints
    #
    class Builder
      #
      # Creates a complete Document from blueprint files
      #
      # This is the primary entry point for generating documentation.
      # It instantiates a Builder, extracts endpoints, compiles them,
      # and returns a structured Document object.
      #
      # @option base_path [String, Pathname, nil] Base directory for blueprint files
      # @option paths [String, Pathname, nil] Specific blueprint file paths
      # @option verbosity_level [Integer] Output verbosity (0 = silent)
      # @option use_cache [Boolean] Whether to use cached endpoint data if available
      #
      # @return [Document] A structured document containing all API endpoints
      #
      # @raise [Error::NoBlueprintsError] If no blueprints are found
      #
      def self.create_document!(**)
        endpoints = new(**).endpoints
        endpoints = Compiler.new(endpoints).compile

        Document.new(endpoints:)
      end

      #
      # Creates a new Builder instance
      #
      # @param base_path [String, Pathname, nil] Base directory for blueprint files
      # @param paths [String, Pathname, nil] Specific blueprint file paths
      # @param verbosity_level [Integer] Output verbosity during test execution (0 = silent)
      # @param use_cache [Boolean] Whether to use cached endpoint data if valid
      #
      # @return [Builder] A new builder instance
      #
      def initialize(base_path: nil, paths: nil, verbosity_level: 0, use_cache: false)
        @cache = Cache.new

        @base_path = base_path
        @paths = paths
        @use_cache = use_cache
        @verbosity_level = verbosity_level
      end

      #
      # Extracts endpoint data from blueprint test executions
      #
      # Runs all blueprints and captures request/response data from each
      # successful test step. Results are cached for subsequent calls
      # when caching is enabled.
      #
      # @return [Array<Hash>] Array of endpoint data hashes containing
      #   request and response information
      #
      # @raise [Error::NoBlueprintsError] If no blueprints are found
      #
      def endpoints
        return @cache.read if @use_cache && @cache.valid?

        endpoints = capture_endpoint_data
        @cache.create(endpoints)

        endpoints
      end

      private

      def capture_endpoint_data
        # contexts will be empty until the blueprints have been ran
        # Must be done before blueprints are loaded
        contexts = register_callback

        blueprints, forge_hooks = SpecForge::Loader.load_blueprints(base_path: @base_path, paths: @paths)
        raise Error::NoBlueprintsError if blueprints.empty?

        run_blueprints(blueprints, verbosity_level: @verbosity_level, hooks: forge_hooks)
        build_endpoints(contexts)
      ensure
        SpecForge.configuration.deregister_callback(:documentation_builder)
      end

      def register_callback
        contexts = []

        SpecForge.configure do |config|
          config.register_callback(:documentation_builder) do |context|
            next if context.failure?

            step = context.step
            next if step.nil? || step.documentation == false
            next unless step.request?

            contexts << context.with(variables: context.variables.dup)
          end

          config.after(:step, :documentation_builder)
        end

        contexts
      end

      def run_blueprints(blueprints, **)
        SpecForge::Forge.ignite.run(blueprints, **)
      end

      def build_endpoints(contexts)
        contexts.map { |context| Extractor.new(context).extract_endpoint }
      end
    end
  end
end
