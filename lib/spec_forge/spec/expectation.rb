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
      def initialize(input, name)
        @input = input
        @name = name
      end

      #
      # Builds the expectation and prepares it to be ran
      #
      # @param request [Request] The request to use when testing
      #
      # @return [Self]
      #
      def compile(request)
        # Only hash is supported
        if !input.is_a?(Hash)
          raise InvalidTypeError.new(input, Hash, for: "expectation")
        end

        load_name
        load_variables
        load_constraints

        # Must be last
        @http_client = HTTPClient.new(request.overlay(**input))

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
          constraints = expectation_forge.constraints
          response = expectation_forge.http_client.call

          binding.pry
          # Status check
          expect(response.status).to eq(constraints.status.result)
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

        @variables = transform_attributes(variables)
      end

      def load_constraints
        constraints = input[:expect]

        if !constraints.is_a?(Hash)
          raise InvalidTypeError.new(constraints, Hash, for: "'expect' on expectation")
        end

        constraints = transform_attributes(constraints)
        @constraints = Constraint.new(**constraints)
      end

      def transform_attributes(hash)
        hash.with_indifferent_access
          .transform_values! { |v| Attribute.from(v) }
          .each_value { |v| v.set_variable_value(variables) if v.is_a?(Attribute::Variable) }
      end
    end
  end
end
