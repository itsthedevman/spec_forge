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

        forges.select do |forge|
          specs = forge.specs

          specs.select! { |spec| spec.file_name == file_name } if file_name
          specs.select! { |spec| spec.name == spec_name } if spec_name

          if expectation_name
            specs.each do |spec|
              spec.expectations.select! { |expectation| expectation.name == expectation_name }
            end
          end

          forge.specs.size > 0 && forge.specs.count(&:expectations) > 0
        end
      end
    end
  end
end
