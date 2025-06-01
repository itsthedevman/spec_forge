# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      #
      # Base class for OpenAPI documentation objects
      #
      # Provides common functionality for OpenAPI specification objects
      # like operations, responses, and schemas.
      #
      class Base
        #
        # The document object containing structured API data
        #
        # @return [Object] The document with endpoint information
        #
        attr_reader :document

        #
        # Additional documentation configuration and metadata
        #
        # @return [Hash] Configuration options for documentation generation
        #
        attr_reader :documentation

        #
        # Creates a new OpenAPI base object
        #
        # @param document [Object] The document object containing API data
        # @param documentation [Hash] Additional documentation configuration
        #
        # @return [Base] A new base instance
        #
        def initialize(document, documentation: {})
          @document = document
          @documentation = documentation
        end
      end
    end
  end
end
