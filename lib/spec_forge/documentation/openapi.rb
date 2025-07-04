# frozen_string_literal: true

module SpecForge
  module Documentation
    #
    # OpenAPI documentation generation functionality
    #
    # Contains classes and modules for generating OpenAPI specifications
    # from SpecForge test data. Supports multiple OpenAPI versions.
    #
    module OpenAPI
    end
  end
end

require_relative "openapi/base"

require_relative "openapi/v3_0/example"
require_relative "openapi/v3_0/media_type"
require_relative "openapi/v3_0/operation"
require_relative "openapi/v3_0/response"
require_relative "openapi/v3_0/schema"
require_relative "openapi/v3_0/tag"
