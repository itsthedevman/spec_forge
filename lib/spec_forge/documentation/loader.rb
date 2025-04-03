# frozen_string_literal: true

module SpecForge
  module Documentation
    class Loader
      include Singleton

      def self.load(forges)
        return [] if forges.blank?

        instance.normalize(forges)
      end

      def normalize(forges)
      end
    end
  end
end
