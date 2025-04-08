# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      module OpenAPI
        class V3_0 < Base # standard:disable Naming/ClassAndModuleCamelCase
          CURRENT_VERSION = "3.0.3"

          def render
            output[:openapi] = ""
            output[:info] = {}
            output[:servers] = []
            output[:tags] = []
            output[:security] = []
            output[:paths] = {}
            output[:components] = {}
            output
          end
        end
      end
    end
  end
end
