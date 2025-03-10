# frozen_string_literal: true

module SpecForge
  class Context
    class Store
      class Entry < Data.define(:scope, :request, :variables, :response)
        def initialize(request:, variables:, response:, scope: :file)
          request = request.to_istruct
          variables = variables.to_istruct
          response = response.to_istruct

          super
        end

        def status = response.status

        def body = response.body

        def headers = response.headers
      end

      def initialize
        @inner = {}
      end

      def store(id, **)
        @inner[id] = Entry.new(**)
      end
    end
  end
end
