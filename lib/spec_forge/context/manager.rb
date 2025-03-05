# frozen_string_literal: true

module SpecForge
  class Context
    class Manager < Data.define(:global, :metadata, :store, :variables)
      def initialize
        super(
          global: Global.new,
          metadata: Metadata.new,
          store: Store.new,
          variables: Variables.new
        )
      end
    end
  end
end
