# frozen_string_literal: true

module SpecForge
  module Documentation
    #
    # OpenAPI specification generation and version management
    #
    # Provides version-aware access to OpenAPI generators and validators.
    # Supports multiple OpenAPI versions through semantic versioning matching.
    #
    module OpenAPI
      #
      # Current OpenAPI version used as default
      #
      # Points to the latest supported OpenAPI version for new specifications.
      #
      # @api private
      #
      CURRENT_VERSION = V30::CURRENT_VERSION

      #
      # Mapping of semantic versions to their generator classes
      #
      # @return [Hash{SemVersion => Class}]
      #
      VERSIONS = {
        V30.to_sem_version => V30
      }.freeze

      #
      # Returns the generator class for the specified OpenAPI version
      #
      # @param version [String, SemVersion] The OpenAPI version (e.g., "3.0")
      #
      # @return [Class] The generator class for the requested version
      #
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
