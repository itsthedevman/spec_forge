# frozen_string_literal: true

require_relative "expectation/constraint"

module SpecForge
  class Spec
    class Expectation
      # Internal
      attr_reader :input, :file_path, :http_client

      # User defined (rest are in available via :http_client)
      attr_reader :name, :variables, :constraints

      #
      # Creates a new Expectation
      #
      # @param input [Hash] A hash containing the various attributes to control the expectation
      # @param name [String] The name of the expectation
      #
      def initialize(name, input, global_options: {})
        @name = name

        if !input.is_a?(Hash)
          raise InvalidTypeError.new(input, Hash, for: "expectation")
        end

        # This allows defining spec level attributes that can be overwritten by the expectation
        @input = global_options.deep_merge(input).deep_symbolize_keys
      end

      #
      # Builds the expectation and prepares it to be ran
      #
      # @return [Self]
      #
      def compile
        load_name
        load_variables

        # Must be after load_variables
        load_constraints

        # Must be last
        @http_client = HTTP::Client.new(variables:, **input.except(:name, :variables, :expect))

        self
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

      def load_name
        name = input[:name]
        return if name.blank?

        @name = name
      end

      def load_variables
        variables = input[:variables] || {}

        if !variables.is_a?(Hash)
          raise InvalidTypeError.new(variables, Hash, for: "'variables' on expectation")
        end

        @variables = Attribute.transform_hash_values(variables)
      end

      def load_constraints
        constraints = input[:expect]

        if !constraints.is_a?(Hash)
          raise InvalidTypeError.new(constraints, Hash, for: "'expect' on expectation")
        end

        constraints = Attribute.transform_hash_values(constraints, variables)
        @constraints = Constraint.new(**constraints)
      end
    end
  end
end
