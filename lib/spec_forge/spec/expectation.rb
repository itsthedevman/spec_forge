# frozen_string_literal: true

require_relative "expectation/constraint"

module SpecForge
  class Spec
    class Expectation
      # Internal
      attr_reader :input, :file_path, :request

      # User defined (including the ones for request)
      attr_reader :name, :variables, :constraints

      # Contains user defined method
      delegate :url, :http_method, :content_type, :query, :body, to: :request

      #
      # Creates a new Expectation
      #
      # @param input [Hash] A hash containing the various attributes to control the expectation
      # @param name [String] The name of the expectation
      # @param file_path [String/Pathname] The path to the file where this expectation is defined
      #
      def initialize(input, name, file_path)
        @input = input
        @name = name
        @file_path = file_path
      end

      #
      # Builds the expectation and prepares it to be ran
      #
      # @param request [Request] The request to use when testing
      #
      # @return [Self]
      #
      def compile(request)
        @request = request

        # Only hash is supported
        if !input.is_a?(Hash)
          raise InvalidTypeError.new(input, Hash, for: "expectation")
        end

        load_name
        load_variables
        load_constraints

        # Must be last
        update_request

        self
      end

      #
      # Converts this expectation to an RSpec example.
      # Note: the scope of the resulting block is expecting the scope of an RSpec example group
      #
      # @return [Proc]
      #
      def to_example_proc
        expectation_forge = self

        # RSpec example group scope
        lambda do |example|
          binding.pry
          response = expectation_forge.request.call
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

      def update_request
        body = input[:body] || {}
        if !body.is_a?(Hash)
          raise InvalidTypeError.new(body, Hash, for: "'body' on expectation")
        end

        params = input[:query] || input[:params] || {}
        if !params.is_a?(Hash)
          raise InvalidTypeError.new(params, Hash, for: "'query' on expectation")
        end

        @request = request.update(body, params)
      end
    end
  end
end
