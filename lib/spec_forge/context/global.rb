# frozen_string_literal: true

module SpecForge
  class Context
    class Global
      attr_reader :variables

      def initialize(variables: {})
        @variables = Variables.new(base: variables)
      end

      def update(variables:)
        @variables.update(base: variables)

        self
      end
    end
  end
end
