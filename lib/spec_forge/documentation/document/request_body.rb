# frozen_string_literal: true

module SpecForge
  module Documentation
    class Document
      class RequestBody < Data.define(:content_type, :type, :content)
      end
    end
  end
end
