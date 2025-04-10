# frozen_string_literal: true

module SpecForge
  module Documentation
    class Document
      class Operation < Data.define(:id, :description, :parameters, :request_body, :responses)
        def initialize(id:, description:, parameters:, request_body:, responses:)
          parameters = parameters.each_pair.map do |name, value|
            [name, Parameter.new(name: name.to_s, **value)]
          end.to_h

          request_body = RequestBody.new(**request_body) if request_body.present?
          responses = responses.map { |r| Response.new(**r) }

          super
        end
      end
    end
  end
end
