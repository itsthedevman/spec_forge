# frozen_string_literal: true

module SpecForge
  module Documentation
    class Document
      class Response < Data.define(:status, :headers, :body)
      end
    end
  end
end
