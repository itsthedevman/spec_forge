# frozen_string_literal: true

module SpecForge
  class Context
    class Variables
      def initialize(base: {}, overlay: {})
        update(base:, overlay:)
      end

      def [](name)
        @active[name]
      end

      def update(base:, overlay: {})
        @base = base
        @overlay = overlay
        @active = base

        self
      end

      def use_overlay(id)
        overlay = @overlay[id]
        return if overlay.blank?

        @active = @base.merge(overlay)
      end
    end
  end
end
