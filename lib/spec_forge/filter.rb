# frozen_string_literal: true

module SpecForge
  #
  # Provides filtering capabilities for test suites based on different criteria
  #
  # The Filter class allows running specific tests by filtering forges, specs,
  # and expectations based on file name, spec name, and expectation name.
  #
  # @example Filtering specs by name
  #   forges = Loader.load_from_files
  #   filtered = Filter.apply(forges, file_name: "users", spec_name: "create_user")
  #
  class Filter
    class << self
      #
      # Prints out a message if any of the filters were used
      #
      # @param forges [Array<Forge>] The collection of forges that was filtered
      # @param file_name [String, nil] Optional file name that was used by the filter
      # @param spec_name [String, nil] Optional spec name that was used by the filter
      # @param expectation_name [String, nil] Optional expectation name that was used by the filter
      #
      def announce(forges, file_name:, spec_name:, expectation_name:)
        filters = {file_name:, spec_name:, expectation_name:}.reject { |k, v| v.blank? }
        return if filters.size == 0

        filters_display = filters.join_map(", ") { |k, v| "#{k.in_quotes} => #{v.in_quotes}" }

        expectation_count = forges.sum do |forge|
          forge.specs.sum { |spec| spec.expectations.size }
        end

        puts "Applied filter #{filters_display}"
        puts "Found #{expectation_count} #{"expectation".pluralize(expectation_count)}"
      end

      #
      # Filters a collection of forges based on specified criteria
      #
      # This method allows running specific tests by filtering forges, specs,
      # and expectations based on file name, spec name, and expectation name.
      # It returns only the forges, specs, and expectations that match the criteria.
      #
      # @param forges [Array<Forge>] The collection of forges to filter
      # @param file_name [String, nil] Optional file name to filter by
      # @param spec_name [String, nil] Optional spec name to filter by
      # @param expectation_name [String, nil] Optional expectation name to filter by
      #
      # @return [Array<Forge>] The filtered collection of forges
      #
      # @raise [ArgumentError] If filtering parameters are provided in an invalid combination
      #
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
