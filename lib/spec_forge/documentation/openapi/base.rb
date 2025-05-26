# frozen_string_literal: true

module SpecForge
  module Documentation
    module OpenAPI
      class Base
        attr_reader :document, :documentation

        def initialize(document, documentation: {})
          @document = document
          @documentation = documentation
        end
      end
    end
  end
end
