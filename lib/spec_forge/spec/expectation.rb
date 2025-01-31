# frozen_string_literal: true

module SpecForge
  class Spec
    class Expectation
      attr_reader :input, :spec, :status, :variables, :json # :xml, :html

      def initialize(input)
        @input = input
      end

      def compile(spec)
        @spec = spec

        # Only hash is supported
        if !input.is_a?(Hash)
          raise InvalidTypeError.new(variables_hash, Hash, for: "expectation")
        end

        # Status is the only required field
        @status = input[:status]
        if @status.blank?
          raise ArgumentError, "'status' must be provided on a expectation"
        end

        # Check for variables (optional) and convert
        @variables = input[:variables] || {}

        if !variables.is_a?(Hash)
          raise InvalidTypeError.new(variables, Hash, for: "'variables' on expectation")
        end

        # Convert the variables and prepare them
        @variables.deep_stringify_keys!
          .transform_values! { |v| Attribute.from(v) }
          .each_value { |v| v.update_lookup_table(@variables) }

        # Check for json (optional) and convert
        @json = input[:json] || {}

        if !json.is_a?(Hash)
          InvalidTypeError.new(json, Hash, for: "'json' on expectation")
        end

        @json.transform_values! { |v| Attribute.from(v) }

        # Create a new copy of the request with any overwritten values
        @request = spec.request.with(**input)

        self
      end
    end
  end
end
