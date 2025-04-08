# frozen_string_literal: true

require_relative "openapi/v3_0"

module SpecForge
  module Documentation
    module Renderers
      class OpenAPI < File
        def self.semantic_version(version_class)
          SemVersion.new(version_class::CURRENT_VERSION)
        end

        CURRENT_VERSION = V3_0::CURRENT_VERSION

        VERSIONS = {
          semantic_version(V3_0) => V3_0
        }.freeze

        def self.[](version)
          version = SemVersion.from_loose_version(version)
          renderer = VERSIONS.find { |k, _v| k.satisfies?("~> #{version}") }&.second

          if renderer.nil?
            raise ArgumentError, "Invalid OpenAPI version provided: #{version.to_s.in_quotes}"
          end

          renderer
        end
      end
    end
  end
end
