# frozen_string_literal: true

module SpecForge
  class Runner
    #
    # Manages metadata for RSpec example groups and examples
    #
    # This class provides methods for setting up correct metadata on RSpec groups
    # and examples, which enables proper error reporting and command-line rerun
    # instructions when tests fail.
    #
    # @example Setting metadata on an example group
    #   Metadata.set_for_group(spec, expectation, example_group)
    #
    class Metadata
      class << self
        #
        # Updates the example group metadata for error reporting
        #
        # Sets the file path, line number, and location information in the
        # example group's metadata. This ensures that RSpec can generate the
        # proper command to rerun the failing tests.
        #
        # @param spec [SpecForge::Spec] The spec being tested
        # @param expectation [SpecForge::Spec::Expectation] The expectation being evaluated
        # @param example_group [RSpec::Core::ExampleGroup] The example group to update
        #
        def set_for_group(spec, expectation, example_group)
          metadata = {
            file_path: spec.file_path,
            absolute_file_path: spec.file_path,
            line_number: expectation.line_number,
            location: spec.file_path,
            rerun_file_path: "#{spec.file_name}:#{spec.name}:\"#{expectation.name}\""
          }

          example_group.metadata.merge!(metadata)
        end

        #
        # Updates the current example's metadata for error reporting
        #
        # Sets location information on the currently running example.
        # This helps RSpec generate more accurate error messages when
        # an exception occurs during test execution.
        #
        # @param spec [SpecForge::Spec] The spec being tested
        # @param expectation [SpecForge::Spec::Expectation] The expectation being evaluated
        #
        def set_for_example(spec, expectation)
          metadata = {location: "#{spec.file_path}:#{expectation.line_number}"}

          RSpec.current_example.metadata.merge!(metadata)
        end
      end
    end
  end
end
