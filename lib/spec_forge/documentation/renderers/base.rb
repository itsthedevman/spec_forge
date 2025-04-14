# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      class Base
        attr_reader :input

        def initialize(input = {})
          @input = input
        end

        def render
          raise "not implemented"
        end

        def to_h
          render
        end

        def to_yaml
          render.to_yaml(stringify_names: true)
        end
      end
    end
  end
end
