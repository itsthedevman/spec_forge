# frozen_string_literal: true

module SpecForge
  module Documentation
    module Renderers
      module OpenAPI
        class Base < File
          def self.to_sem_version
            SemVersion.new(CURRENT_VERSION)
          end
        end
      end
    end
  end
end
