# frozen_string_literal: true

module SpecForge
  class Loader
    class Filter
      def initialize(blueprints)
        @blueprints = blueprints
      end

      def run(path: nil, tags: [], skip_tags: [])
        filter_by_path(path)
        filter_by_tags(tags, skip_tags)
        remove_empty_blueprints

        @blueprints
      end

      private

      def filter_by_path(path)
        return if path.blank?

        base_path = SpecForge.blueprints_path
        path = path.relative_path_from(base_path).to_s
          .delete_suffix(".yml")
          .delete_suffix(".yaml")

        @blueprints.select! do |blueprint|
          blueprint[:name].starts_with?(path)
        end
      end

      def filter_by_tags(tags, skip_tags)
        include_by_tag(tags)
        exclude_by_tag(skip_tags)
      end

      def include_by_tag(tags)
        return if tags.blank?

        @blueprints.each do |blueprint|
          blueprint[:steps].select! do |step|
            step[:tags].intersect?(tags)
          end
        end
      end

      def exclude_by_tag(tags)
        return if tags.blank?

        @blueprints.each do |blueprint|
          blueprint[:steps].reject! do |step|
            step[:tags].intersect?(tags)
          end
        end
      end

      def remove_empty_blueprints
        @blueprints.delete_if { |blueprint| blueprint[:steps].blank? }
      end
    end
  end
end
