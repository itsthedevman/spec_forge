# frozen_string_literal: true

module SpecForge
  module Documentation
    class Document < Data.define(:endpoints)
      def initialize(endpoints: {})
        endpoints = endpoints.transform_values do |operations|
          operations.transform_keys(&:downcase)
            .transform_values! { |op| Operation.new(**op) }
        end

        super
      end
    end
  end
end

require_relative "document/operation"
require_relative "document/parameter"
require_relative "document/request_body"
require_relative "document/response"
require_relative "document/response_body"
