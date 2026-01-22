# frozen_string_literal: true

module SpecForge
  module Documentation
    # TODO: Docs
    module OpenAPI
      #
      # Current OpenAPI version used as default
      #
      # Points to the latest supported OpenAPI version for new specifications.
      #
      # @api private
      #
      CURRENT_VERSION = V30::CURRENT_VERSION

      # TODO: Docs
      VERSIONS = {
        V30.to_sem_version => V30
      }.freeze

      # TODO: Docs
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
