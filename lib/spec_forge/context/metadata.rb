# frozen_string_literal: true

module SpecForge
  class Context
    #
    # Stores file path information about the current spec file being executed.
    #
    # @example Basic usage
    #   metadata = Metadata.new(
    #     file_name: "users",
    #     file_path: "/path/to/spec_forge/specs/users.yml",
    #     relative_path: "specs/users.yml"
    #   )
    #
    #   metadata.file_name     #=> "users"
    #   metadata.relative_path #=> "specs/users.yml"
    #
    class Metadata
      # @return [String] The base name of the spec file without extension (e.g., "users")
      attr_reader :file_name

      # @return [String] The absolute path to the spec file
      attr_reader :file_path

      # @return [String] The path relative to the spec_forge directory
      attr_reader :relative_path

      #
      # Creates a new Metadata instance
      #
      # @param file_name [String] The base name of the spec file without extension
      # @param file_path [String] The absolute path to the spec file
      # @param relative_path [String] The path relative to the spec_forge directory
      #
      # @return [Metadata] The new Metadata instance
      #
      def initialize(file_name: "", file_path: "", relative_path: "")
        update(file_name:, file_path:, relative_path:)
      end

      #
      # Updates the metadata values
      #
      # @param file_name [String] The base name of the spec file without extension
      # @param file_path [String] The absolute path to the spec file
      # @param relative_path [String] The path relative to the spec_forge directory
      #
      # @return [self]
      #
      def update(file_name:, file_path:, relative_path:)
        @file_name = file_name
        @file_path = file_path
        @relative_path = relative_path

        self
      end
    end
  end
end
