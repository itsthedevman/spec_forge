# frozen_string_literal: true

module SpecForge
  module Documentation
    class Document
      class Info < Data.define(:title, :version, :description, :contact, :license)
        def initialize(title: "", version: "", description: "", contact: {}, license: {})
          contact = contact.to_istruct
          license = license.to_istruct

          super
        end
      end
    end
  end
end
