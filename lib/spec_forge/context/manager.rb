# frozen_string_literal: true

module SpecForge
  class Context
    class Manager < Context
      def initialize
        @global = Global.new
        @metadata = Metadata.new
        @store = Store.new
        @variables = Variables.new
      end

      def clear
        @global.clear
        @metadata.clear
        @store.clear
        @variables.clear
      end

      def store(context, data)
        context = retrieve_context(context)
        context.store(data)
      end

      def retrieve(context, *path)
        context = retrieve_context(context)
        context.retrieve(path)
      end

      private

      def retrieve_context(name)
        case name.to_sym
        when :global
          @global
        when :metadata
          @metadata
        when :store
          @store
        when :variables
          @variables
        end
      end
    end
  end
end
