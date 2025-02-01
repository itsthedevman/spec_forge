# frozen_string_literal: true

module SpecForge
  class Spec
    class Expectation
      attr_reader :input, :name, :file_path, :status, :variables, :json, :request # :xml, :html

      delegate :url, :http_method, :content_type, :params, :body, to: :request

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

        # Status is the only required field
        load_name
        load_status
        load_variables
        load_json

        # Must be after the loads
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
        lambda do |example|
          binding.pry
        end
      end

      private

      def load_name
        name = input[:name]
        return if name.blank?

        @name = name
      end

      def load_status
        status = input[:status]

        @status =
          case status
          when String
            status.to_i
          when Integer
            status
          else
            raise InvalidTypeError.new(
              status, "Integer | String",
              for: "'status' on expectation"
            )
          end
      end

      def load_variables
        variables = input[:variables] || {}

        if !variables.is_a?(Hash)
          raise InvalidTypeError.new(variables, Hash, for: "'variables' on expectation")
        end

        @variables = transform_attributes(variables)
      end

      def load_json
        json = input[:json] || {}

        if !json.is_a?(Hash)
          raise InvalidTypeError.new(json, Hash, for: "'json' on expectation")
        end

        @json = transform_attributes(json)
      end

      def transform_attributes(hash)
        hash.with_indifferent_access
          .transform_values! { |v| Attribute.from(v) }
          .each_value(&method(:update_variables))
      end

      def update_variables(value)
        value.set_variable_value(variables) if value.is_a?(Attribute::Variable)
      end

      def update_request
        body = input[:body] || {}
        if !body.is_a?(Hash)
          raise InvalidTypeError.new(body, Hash, for: "'body' on expectation")
        end

        params = input[:params] || {}
        if !params.is_a?(Hash)
          raise InvalidTypeError.new(params, Hash, for: "'params' on expectation")
        end

        @request = request.update(body, params)
      end
    end
  end
end
