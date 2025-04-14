# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      class File < Base
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
