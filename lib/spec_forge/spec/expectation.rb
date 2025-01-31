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
        raise TypeError, "Expected Hash, got #{input.class}" if !input.is_a?(Hash)

        # Status is the only required field
        @status = input[:status]
        raise ArgumentError, "Missing 'status'" if @status.blank?

        # Check for variables (optional) and convert
        @variables = input[:variables] || {}
        raise TypeError, "Expected Hash, got #{variables.class}" if !variables.is_a?(Hash)

        @variables.deep_stringify_keys!
          .transform_values! { |v| Attribute.from(v) }
          .each_value { |v| v.update_lookup_table(@variables) }

        # Check for json (optional) and convert
        @json = input[:json] || {}
        raise TypeError, "Expected Hash, got #{json.class}" if !json.is_a?(Hash)

        @json.transform_values! { |v| Attribute.from(v) }

        # Create a new copy of the request with any overwritten values
        @request = spec.request.with(**input)

        self
      end
    end
  end
end
