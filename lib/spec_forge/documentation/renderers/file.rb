# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      #
      # Renderer that can write documentation to files
      #
      # Extends the base renderer with file writing capabilities.
      #
      # @example Writing documentation to a file
      #   File.new(document).to_file("api.yml")
      #
      class File < Base
        #
        # Writes the rendered output to a file
        #
        # Automatically determines the appropriate format based on file extension
        #
        # @param file_path [String, Pathname] Path to write the file to
        #
        def to_file(file_path)
          output = render

          file_extension = file_path.extname
          content =
            if output.is_a?(String)
              output
            elsif file_extension == ".json"
              JSON.pretty_generate(output)
            elsif file_extension == ".yml" || file_extension == ".yaml"
              output.to_yaml(stringify_names: true)
            end

          ::File.write(file_path, content)
        end
      end
    end
  end
end
