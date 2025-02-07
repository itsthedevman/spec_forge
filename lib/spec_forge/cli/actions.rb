# frozen_string_literal: true

module SpecForge
  class CLI
    module Actions
      def self.included(base)
        base.define_method(:actions) do
          @actions ||= ActionContext.new
        end
      end
    end

    class ActionContext < Thor
      include Thor::Actions

      def initialize(...)
        self.class.source_root(File.expand_path("../../templates", __dir__))
        self.destination_root = SpecForge.root
        self.options = {}
      end
    end
  end
end
