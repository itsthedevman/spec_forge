# frozen_string_literal: true

module SpecForge
  class Spec
    class Expectation
      attr_reader :input, :name, :file_path, :spec, :status, :variables, :json, :request # :xml, :html

      delegate :url, :http_method, :content_type, :params, :body, to: :request

      def initialize(input, name, file_path)
        @input = input
        @name = name
        @file_path = file_path
      end

      def compile(request)
        @request = request

        # Only hash is supported
        if !input.is_a?(Hash)
          raise InvalidTypeError.new(variables_hash, Hash, for: "expectation")
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
        @status = input[:status]

        if status.blank?
          raise ArgumentError, "'status' must be provided on a expectation"
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
        @json = input[:json] || {}

        if !json.is_a?(Hash)
          InvalidTypeError.new(json, Hash, for: "'json' on expectation")
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
          InvalidTypeError.new(body, Hash, for: "'body' on expectation")
        end

        params = input[:params] || {}
        if !params.is_a?(Hash)
          InvalidTypeError.new(params, Hash, for: "'params' on expectation")
        end

        @request = request.with(
          body: request.body.merge(body),
          params: request.params.merge(params)
        )
      end
    end
  end
end
