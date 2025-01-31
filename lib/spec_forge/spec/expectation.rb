# frozen_string_literal: true

module SpecForge
  class Spec
    class Expectation
      attr_reader :input, :name, :spec, :status, :variables, :json # :xml, :html

      def initialize(input, name)
        @input = input
        @name = name
      end

      def compile(spec)
        @spec = spec

        # Only hash is supported
        if !input.is_a?(Hash)
          raise InvalidTypeError.new(variables_hash, Hash, for: "expectation")
        end

        # Status is the only required field
        load_status
        load_variables
        load_json

        update_request
        self
      end

      def to_example_proc
        lambda do |example|
          binding.pry
        end
      end

      private

      def load_status
        @status = input[:status]

        if status.blank?
          raise ArgumentError, "'status' must be provided on a expectation"
        end
      end

      def load_variables
        @variables = input[:variables] || {}

        if !variables.is_a?(Hash)
          raise InvalidTypeError.new(variables, Hash, for: "'variables' on expectation")
        end

        # Convert the variables and prepare them
        variables.deep_stringify_keys!
          .transform_values! { |v| Attribute.from(v) }
          .each_value { |v| v.update_lookup_table(variables) }
      end

      def load_json
        @json = input[:json] || {}

        if !json.is_a?(Hash)
          InvalidTypeError.new(json, Hash, for: "'json' on expectation")
        end

        json.transform_values! { |v| Attribute.from(v) }
      end

      def update_request
        @request = spec.request.with(**input)
      end
    end
  end
end
