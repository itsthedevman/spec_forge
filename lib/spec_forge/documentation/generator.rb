# frozen_string_literal: true

module SpecForge
  module Documentation
    #
    # Base class for all documentation generators
    #
    # Provides the common interface and shared functionality for generators
    # that transform SpecForge documents into various output formats.
    # Subclasses implement format-specific generation logic.
    #
    # @example Creating a custom generator
    #   class MyGenerator < Generator
    #     def generate
    #       # Transform input document to custom format
    #     end
    #   end
    #
    class Generator
      #
      # Converts the generator's version to a semantic version object
      #
      # @return [SemVersion] The semantic version
      #
      def self.to_sem_version
        SemVersion.new(const_get("CURRENT_VERSION"))
      end

      #
      # Generates documentation from test data with optional caching
      #
      # @param use_cache [Boolean] Whether to use cached test data if available
      #
      # @return [Object] The generated documentation in the target format
      #
      # @raise [RuntimeError] Must be implemented by subclasses
      #
      def self.generate(use_cache: false)
        raise "not implemented"
      end

      #
      # Validates the generated output according to format specifications
      #
      # @param input [Object] The generated documentation to validate
      #
      # @return [void]
      #
      # @raise [RuntimeError] Must be implemented by subclasses
      #
      def self.validate!(input)
        raise "not implemented"
      end

      #
      # The input document containing structured API data
      #
      # Contains all the endpoint information extracted from tests,
      # organized and ready for transformation into the target format.
      #
      # @return [Document] The document to be processed by the generator
      #
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
