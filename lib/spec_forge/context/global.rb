# frozen_string_literal: true

module SpecForge
  class Context
    class Global < Context
      def initialize(variables: {})
        @variables = Variables.new(variables)
      end

      def clear
        @variables.clear
      end

      def store(hash)
        @variables.store(hash[:variables]) if hash.key?(:variables)
      end

      def retrieve(*path)
        namespace = path.first

        object =
          case namespace
          when "variables"
            @variables
          else
            raise ArgumentError,
              "Invalid namespace for Global context. Expected \"variables\", got #{namespace}"
          end

        object.retrieve(path.second)
      end
    end
  end
end
