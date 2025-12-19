# frozen_string_literal: true

module SpecForge
  class Step
    class Source < Data.define(:file_name, :line_number)
      def to_s
        "#{file_name}:#{line_number}"
      end
    end
  end
end
