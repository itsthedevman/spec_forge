# frozen_string_literal: true

module SpecForge
  module Documentation
    class Document
      class Operation < Data.define(:id, :description, :parameters, :requests, :responses)
        def initialize(id:, description:, parameters:, requests:, responses:)
          parameters = parameters.each_pair.map do |name, value|
            [name, Parameter.new(name: name.to_s, **value)]
          end.to_h

          requests = requests.map { |r| RequestBody.new(**r) }
          responses = responses.map { |r| Response.new(**r) }

          super
        end
      end
    end
  end
end
