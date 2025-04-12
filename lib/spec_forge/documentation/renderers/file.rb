# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      class File < Base
        def to_file(file_path)
          render

          content =
            if output.is_a?(String)
              output
            else
              JSON.pretty_generate(output)
            end

          ::File.write(file_path, content)
        end
      end
    end
  end
end
