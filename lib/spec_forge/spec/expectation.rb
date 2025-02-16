# frozen_string_literal: true

require_relative "expectation/constraint"

module SpecForge
  class Spec
    class Expectation
      attr_predicate :debug

      attr_reader :name, :variables, :constraints, :http_client

      #
      # Creates a new Expectation
      #
      # @param input [Hash] A hash containing the various attributes to control the expectation
      # @param name [String] The name of the expectation
      #
      def initialize(input, global_options: {})
        # This allows defining spec level attributes that can be overwritten by the expectation
        input = Attribute.from(Configuration.overlay_options(global_options, input))

        load_debug(input)
        load_variables(input)

        # Must be after load_variables
        load_constraints(input)

        @http_client = HTTP::Client.new(
          variables:, **input.except(:name, :variables, :expect, :debug)
        )

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
        if (name = input[:name].resolve.presence)
          @name += " - #{name}"
        end
      end

      def load_variables(input)
        @variables = Attribute.bind_variables(input[:variables], input[:variables])
      end

      def load_debug(input)
        @debug = input[:debug].resolve
      end

      def load_constraints(input)
        constraints = Attribute.bind_variables(input[:expect], variables)
        @constraints = Constraint.new(**constraints)
      end
    end
  end
end
