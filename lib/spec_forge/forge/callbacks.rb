# frozen_string_literal: true

module SpecForge
  class Forge
    class Callbacks
      def initialize
        @hooks = {
          before_each: [],
          after_each: [],
          before_file: [],
          after_file: []
        }
      end
    end
  end
end
