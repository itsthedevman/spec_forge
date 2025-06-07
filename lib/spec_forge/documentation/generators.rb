# frozen_string_literal: true

module SpecForge
  module Documentation
    #
    # Documentation rendering functionality
    #
    # Contains generator classes for transforming SpecForge documents
    # into various output formats like OpenAPI specifications.
    #
    module Generators
    end
  end
end

require_relative "generators/base"
require_relative "generators/openapi"
