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
        load_name(name, input)

        # This allows defining spec level attributes that can be overwritten by the expectation
        input = Attribute.from(overlay_options(global_options, input))

        load_variables(input)

        # Must be after load_variables
        load_constraints(input)

        # Must be last
        @http_client = HTTP::Client.new(variables:, **input.except(:name, :variables, :expect))
      end

      private

      def overlay_options(source, overlay)
        # Remove any blank values to avoid overwriting anything from source
        overlay = overlay.delete_if { |_k, v| v.blank? }
        source.deep_merge(overlay)
      end

      def load_name(name, input)
        @name = input[:name].presence || name
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
