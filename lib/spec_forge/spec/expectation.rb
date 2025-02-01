# frozen_string_literal: true

module SpecForge
  class Spec
    class Expectation
      attr_reader :input, :name, :spec, :status, :variables, :json # :xml, :html

      delegate :url, :http_method, :content_type, :params, :body, to: :@request

      def initialize(input, name)
        @input = input
        @name = name
      end

      def compile(request)
        puts "Expectation #{name} is compiling"

        # Only hash is supported
        if !input.is_a?(Hash)
          raise InvalidTypeError.new(variables_hash, Hash, for: "expectation")
        end

        update_request(request)

        # Status is the only required field
        load_name
        load_status
        load_variables
        load_json

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

        @variables = variables.deep_stringify_keys

        # Convert the variables and prepare them
        @variables
          .transform_values! { |v| Attribute.from(v) }
          .each_value { |v| v.update_lookup_table(variables) if v.is_a?(Attribute::Variable) }
      end

      def load_body
        @body = input[:body] || {}

        if body.is_a?(Hash)
          InvalidTypeError.new(body, Hash, for: "'body' on expectation")
        end

        body.transform_values { |v| Attribute.from(v) }
      end

      def load_json
        @json = input[:json] || {}

        if !json.is_a?(Hash)
          InvalidTypeError.new(json, Hash, for: "'json' on expectation")
        end

        @json = json.deep_stringify_keys
          .transform_values! { |v| Attribute.from(v) }
      end

      def update_request
        @request = request.with(**input)
      end
    end
  end
end
