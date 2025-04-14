# frozen_string_literal: true

require_relative "openapi/base"
require_relative "openapi/v3_0"

module SpecForge
  module Documentation
    module Renderers
      #
      # Namespace for OpenAPI renderers
      #
      # Contains version-specific OpenAPI renderers and helper methods
      # for selecting the appropriate renderer.
      #
      module OpenAPI
        CURRENT_VERSION = V3_0::CURRENT_VERSION

        VERSIONS = {
          V3_0.to_sem_version => V3_0
        }.freeze

        #
        # Selects an OpenAPI renderer by version
        #
        # @param version [String] OpenAPI version (e.g., "3.0")
        #
        # @return [Class] The appropriate renderer class
        # @raise [ArgumentError] If the version is not supported
        #
        def self.[](version)
          version = SemVersion.from_loose_version(version)
          renderer = VERSIONS.value_where { |k, _v| k.satisfies?("~> #{version}") }

          if renderer.nil?
            raise ArgumentError, "Invalid OpenAPI version provided: #{version.to_s.in_quotes}"
          end

          renderer
        end
      end
    end
  end
end
