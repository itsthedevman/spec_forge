# frozen_string_literal: true

require_relative "expectation/constraint"

module SpecForge
  class Spec
    class Expectation
      attr_predicate :debug

      attr_reader :name, :variables, :constraints, :http_client

      def initialize(input)
        load_constraints(input)
        load_debug(input)
        load_variables(input)

        @http_client = HTTP::Client.new(**input.except(:name, :variables, :expect, :debug))

        # Must be after http_client
        load_name(input)
      end

      def to_h
        {
          name:,
          debug: debug?,
          variables: variables.resolve,
          request: http_client.request.to_h,
          constraints: constraints.to_h
        }
      end

      private

      def load_name(input)
        # GET /users
        @name = "#{http_client.request.http_verb.upcase} #{http_client.request.url}"

        # GET /users - Returns a 404
        if (name = input[:name].presence)
          @name += " - #{name}"
        end
      end

      def load_variables(input)
        @variables = Attribute.from(input[:variables])
      end

      def load_debug(input)
        @debug = Attribute.from(input[:debug])
      end

      def load_constraints(input)
        @constraints = Constraint.new(**constraints)
      end
    end
  end
end
