# frozen_string_literal: true

module SpecForge
  module Documentation
    #
    # Documentation rendering functionality
    #
    # Contains renderer classes for transforming SpecForge documents
    # into various output formats like OpenAPI specifications.
    #
    module Renderers
    end
  end
end

require_relative "renderers/base"
require_relative "renderers/file"
require_relative "renderers/openapi"
