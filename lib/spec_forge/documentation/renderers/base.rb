# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      #
      # Base class for all documentation renderers
      #
      # Provides common functionality for transforming document objects
      # into specific documentation formats.
      #
      # @example Implementing a custom renderer
      #   class MyRenderer < Base
      #     def render
      #       # Transform @input into desired format
      #     end
      #   end
      #
      class Base
        attr_reader :input

        #
        # Initializes a new renderer
        #
        # @param input [Hash, Document] The document to render
        #
        # @return [Base] A new renderer instance
        #
        def initialize(input = {})
          @input = input
        end

        #
        # Renders the document into a specific format
        #
        # @raise [RuntimeError] Must be implemented by subclasses
        #
        # @return [Object] The rendered document
        #
        def render
          raise "not implemented"
        end
      end
    end
  end
end
