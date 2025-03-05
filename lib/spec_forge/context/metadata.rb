# frozen_string_literal: true

module SpecForge
  class Context
    class Metadata
      attr_reader :file_name, :file_path, :relative_path

      def initialize(file_name: "", file_path: "", relative_path: "")
        @file_name = file_name
        @file_path = file_path
        @relative_path = relative_path
      end

      def update(context)
        @file_name = context.file_name
        @file_path = context.file_path
        @relative_path = context.relative_path

        self
      end
    end
  end
end
