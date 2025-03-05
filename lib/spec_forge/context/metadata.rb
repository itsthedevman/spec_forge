# frozen_string_literal: true

module SpecForge
  class Context
    class Metadata
      attr_reader :file_name, :file_path, :relative_path

      def initialize(file_name: "", file_path: "", relative_path: "")
        update(file_name:, file_path:, relative_path:)
      end

      def update(file_name:, file_path:, relative_path:)
        @file_name = file_name
        @file_path = file_path
        @relative_path = relative_path
      end
    end
  end
end
