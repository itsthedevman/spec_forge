# frozen_string_literal: true

module SpecForge
  module Documentation
    # TODO: Documentation
    class Builder
      def self.load_document(base_path: nil, paths: nil, use_cache: false)
        endpoints = new(use_cache:).endpoints

        Builder.document_from_endpoints(endpoints)
      end

      # TODO: Documentation
      def initialize(use_cache: false)
        @use_cache = use_cache
        @cache = Cache.new
      end

      # TODO: Documentation
      def endpoints
        return cache.read if use_cache && cache.valid?

        endpoints = capture_endpoint_data
        @cache.create(endpoints)

        endpoints
      end

      private

      def capture_endpoint_data
        successes = []

        # Hook a callback to collect the successful request steps
        callback_name =
          SpecForge.configuration.after(:step) do |context|
            next if context.failure?

            step = context.step
            next if step.nil? || step.documentation == false
            next unless step.request?

            successes << context
          end

        blueprints, forge_hooks = SpecForge::Loader.load_blueprints
        raise NoBlueprintsError if blueprints.empty?

        SpecForge::Forge.ignite.run(blueprints, verbosity_level:, hooks: forge_hooks)

        successes.map { |d| extract_endpoint(d) }
      ensure
        SpecForge.configuration.deregister_callback(callback_name) if callback_name
      end
    end
  end
end
