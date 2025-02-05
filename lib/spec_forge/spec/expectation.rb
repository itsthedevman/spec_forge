# frozen_string_literal: true

require_relative "expectation/constraint"

module SpecForge
  class Spec
    class Expectation
      attr_reader :name, :variables, :constraints, :http_client

      #
      # Creates a new Expectation
      #
      # @param input [Hash] A hash containing the various attributes to control the expectation
      # @param name [String] The name of the expectation
      #
      def initialize(name, input, global_options: {})
        @name = name

        # This allows defining spec level attributes that can be overwritten by the expectation
        input = Attribute.from(global_options.deep_merge(input))

        load_name(input)
        load_variables(input)

        # Must be after load_variables
        load_constraints(input)

        # Must be last
        @http_client = HTTP::Client.new(variables:, **input.except(:name, :variables, :expect))
      end

      #
      # Converts this expectation to an RSpec example.
      # Note: the scope of the resulting block is expecting the scope of an RSpec example group
      #
      # @return [Proc]
      #
      def to_spec_proc
        expectation_forge = self

        # RSpec example group scope
        lambda do |example|
          response = expectation_forge.http_client.call
          constraints = expectation_forge.constraints

          # Status check
          expect(response.status).to eq(constraints.status.resolve)

          # JSON check
          if constraints.json.size > 0
            response_body = response.body
            body_constraint = constraints.json.resolve.deep_stringify_keys

            expect(response_body).to match(body_constraint)
          end
        end
      end

      private

      def load_name(input)
        name = input[:name]
        return if name.blank?

        @name = name
      end

      def load_variables(input)
        @variables = input[:variables]
      end

      def load_constraints(input)
        constraints = Attribute.update_hash_values(input[:expect], variables)
        @constraints = Constraint.new(**constraints)
      end
    end
  end
end
