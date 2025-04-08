# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      class Base
        attr_reader :input, :output

        def initialize(input = {})
          @input = input
          @output = {}
        end

        def render
          raise "not implemented"
        end

        def to_h
          render
          output
        end

        def to_yaml
          to_h.to_yaml
        end
      end
    end
  end
end
