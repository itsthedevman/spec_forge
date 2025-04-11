# frozen_string_literal: true

module SpecForge
  module Documentation
    class Document
      class RequestBody < Data.define(:name, :content_type, :type, :content)
      end
    end
  end
end
