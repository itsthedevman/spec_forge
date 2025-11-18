# frozen_string_literal: true

module SpecForge
  module Documentation
    module Generators
      #
      # Namespace for OpenAPI generators
      #
      # Contains version-specific OpenAPI generators and helper methods
      # for selecting the appropriate generator.
      #
      module OpenAPI
        #
        # Current OpenAPI version used as default
        #
        # Points to the latest supported OpenAPI version for new specifications.
        #
        # @api private
        #
        CURRENT_VERSION = V3_0::CURRENT_VERSION

        #
        # Mapping of OpenAPI versions to their generator classes
        #
        # Used for version selection when generating OpenAPI documentation.
        # Keys are SemVersion objects, values are generator classes.
        #
        # @api private
        #
        VERSIONS = {
          V3_0.to_sem_version => V3_0
        }.freeze

        #
        # Selects an OpenAPI generator by version
        #
        # @param version [String] OpenAPI version (e.g., "3.0")
        #
        # @return [Class] The appropriate generator class
        # @raise [ArgumentError] If the version is not supported
        #
        def self.[](version)
          version = SemVersion.from_loose_version(version)
          generator = VERSIONS.value_where { |k, _v| k.satisfies?("~> #{version}") }

          if generator.nil?
            raise ArgumentError, "Invalid OpenAPI version provided: #{version.to_s.in_quotes}"
          end

          generator
        end
      end
    end
  end
end
