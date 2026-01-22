# frozen_string_literal: true

module SpecForge
  class Forge
    # TODO: documentation
    class Context < Data.define(:variables, :blueprint, :step, :error)
      def initialize(**context)
        context[:variables] ||= nil
        context[:blueprint] ||= nil
        context[:step] ||= nil
        context[:error] ||= nil

        super(context)
      end

      # TODO: Documentation
      def success?
        error.nil?
      end

      # TODO: Documentation
      def failure?
        !success?
      end
    end
  end
end
