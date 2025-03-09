# frozen_string_literal: true

module SpecForge
  class CLI
    #
    # Provides helper methods for CLI actions such as file generation
    # and template rendering through Thor::Actions integration.
    #
    # @example Using actions in a command
    #   actions.template("my_template.tt", "destination/path.rb")
    #
    module Actions
      #
      # Internal Ruby hook, called when the module is included in another file
      #
      # @param base [Class] The class that included this module
      #
      def self.included(base)
        #
        # Returns an ActionContext instance for performing file operations
        #
        # @return [ActionContext] The action context for this command
        #
        base.define_method(:actions) do
          @actions ||= ActionContext.new
        end
      end
    end

    #
    # Provides a context for Thor actions that configures paths and options
    #
    # @private
    #
    class ActionContext < Thor
      include Thor::Actions

      #
      # Creates a new action context with SpecForge template paths configured
      #
      # @return [ActionContext] A new context for Thor actions
      #
      def initialize(...)
        self.class.source_root(File.expand_path("../../templates", __dir__))
        self.destination_root = SpecForge.root
        self.options = {}
      end
    end
  end
end
