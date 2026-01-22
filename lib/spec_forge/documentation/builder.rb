# frozen_string_literal: true

module SpecForge
  module Documentation
    # TODO: Documentation
    class Builder
      def self.create_document!(**)
        endpoints = new(**).endpoints
        endpoints = Compiler.new(endpoints).compile

        Document.new(endpoints:)
      end

      # TODO: Documentation
      def initialize(base_path: nil, paths: nil, verbosity_level: 0, use_cache: false)
        @cache = Cache.new

        @base_path = base_path
        @paths = paths
        @use_cache = use_cache
        @verbosity_level = verbosity_level
      end

      # TODO: Documentation
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
