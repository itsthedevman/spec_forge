# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      class Base
        def self.render(use_cache: false)
          raise "not implemented"
        end

        def self.validate!(input)
          raise "not implemented"
        end

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
