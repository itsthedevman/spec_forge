# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      module OpenAPI
        class V3_0 < Base # standard:disable Naming/ClassAndModuleCamelCase
          CURRENT_VERSION = "3.0.4"

          def config
            @config ||= Documentation.config[:openapi]
          end

          def render
            output[:openapi] = config[:version].presence || CURRENT_VERSION
            output[:info] = export_info
            output[:servers] = export_servers
            output[:tags] = []
            output[:security] = []
            output[:paths] = {}
            output[:components] = {}
            output
          end

          protected

          def export_info
            input.info.to_h
          end

          def export_servers
            config[:servers] || []
          end
        end
      end
    end
  end
end
