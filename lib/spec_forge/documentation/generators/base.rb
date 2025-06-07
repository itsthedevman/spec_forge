# frozen_string_literal: true

module SpecForge
  module Documentation
    module Generators
      class Base
        def self.generate(use_cache: false)
          raise "not implemented"
        end

        def self.validate!(input)
          raise "not implemented"
        end

        attr_reader :input

        #
        # Initializes a new generators
        #
        # @param input [Hash, Document] The document to generate
        #
        # @return [Base] A new generator instance
        #
        def initialize(input = {})
          @input = input
        end

        #
        # Generates the document into a specific format
        #
        # @raise [RuntimeError] Must be implemented by subclasses
        #
        # @return [Object] The generated document
        #
        def generate
          raise "not implemented"
        end
      end
    end
  end
end
