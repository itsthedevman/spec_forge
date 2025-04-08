# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      class OpenAPI < File
        class V3_0 < OpenAPI # standard:disable Naming/ClassAndModuleCamelCase
          CURRENT_VERSION = "3.0.3"
        end
      end
    end
  end
end
