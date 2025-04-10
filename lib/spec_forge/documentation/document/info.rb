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

        def to_h
          super.to_deep_h
        end
      end
    end
  end
end
