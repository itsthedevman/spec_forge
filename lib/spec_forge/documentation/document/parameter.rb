# frozen_string_literal: true

module SpecForge
  module Documentation
    class Document
      #
      # Represents a parameter for an API operation
      #
      # Parameters can appear in various locations (path, query, header)
      # and have different types and validation rules.
      #
      # @example Path parameter
      #   Parameter.new(name: "id", location: "path", type: "integer")
      #
      # @example Query parameter
      #   Parameter.new(name: "limit", location: "query", type: "integer")
      #
      class Parameter < Data.define(:name, :location, :type)
      end
    end
  end
end
