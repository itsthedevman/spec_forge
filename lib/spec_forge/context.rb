# frozen_string_literal: true

module SpecForge
  class Context < Data.define(:global, :metadata, :store, :variables)
    def initialize(global: {}, metadata: {}, variables: {})
      super(
        global: Global.new(**global),
        metadata: Metadata.new(**metadata),
        store: Store.new,
        variables: Variables.new(**variables)
      )
    end
  end
end

require_relative "context/global"
require_relative "context/metadata"
require_relative "context/store"
require_relative "context/variables"
