# frozen_string_literal: true

module SpecForge
  class Loader
    class Filter
      def initialize(blueprints)
        @blueprints = blueprints
      end

      def run(path: nil, tags: [], skip_tags: [])
      end
    end
  end
end
