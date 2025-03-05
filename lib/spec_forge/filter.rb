# frozen_string_literal: true

module SpecForge
  class Filter
    class << self
      def apply(forges, file_name: nil, spec_name: nil, expectation_name: nil)
        # Guard against invalid partial filters
        if expectation_name && spec_name.blank?
          raise ArgumentError, "The spec's name is required when filtering by an expectation's name"
        end

        if spec_name && file_name.blank?
          raise ArgumentError, "The spec's filename is required when filtering by a spec's name"
        end

        forges.filter_map do |forge|
          specs = forge.specs.filter_map do |spec|
            next if file_name && spec.file_name != file_name  # File filter
            next if spec_name && spec.name != spec_name       # Name filter

            # Expectation filter
            next spec unless expectation_name

            expectations = spec.expectations.select { |e| e.name == expectation_name }
            next if expectations.empty?

            spec.expectations = expectations
            spec
          end

          next if specs.empty?

          forge.specs = specs
          forge
        end
      end
    end
  end
end
