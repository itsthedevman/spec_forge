# frozen_string_literal: true

module SpecForge
  module Documentation
    class Document
      class Parameter < Data.define(:name, :location, :type)
      end
    end
  end
end
