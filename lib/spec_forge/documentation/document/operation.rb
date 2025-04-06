# frozen_string_literal: true

module SpecForge
  module Documentation
    class Document
      class Operation < Data.define(:id, :summary, :parameters, :request_body, :responses)
        def initialize(id:, summary:, parameters:, request_body:, responses:)
          parameters = parameters.each_pair.map do |name, value|
            [name, Parameter.new(name:, **value)]
          end.to_h

          responses = responses.map { |r| Response.new(**r) }

          super
        end
      end
    end
  end
end
