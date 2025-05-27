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
        def to_file(file_path, file_format:)
          output = render

          content =
            if file_format == "json"
              JSON.pretty_generate(output)
            else
              # Psych will automatically convert same objects to aliases
              # Psych provides no functionality to disable that
              # So this is the workaround. Convert to JSON, convert back from JSON, then to YAML.
              # Merp.
              output.to_json.to_h.to_yaml(stringify_names: true)
            end

          ::File.write(file_path, content)
        end
      end
    end
  end
end
