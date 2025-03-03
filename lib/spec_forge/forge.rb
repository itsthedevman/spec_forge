# frozen_string_literal: true

module SpecForge
  class Forge
    attr_reader :global_context, :metadata_context, :specs

    def initialize(global, metadata, specs)
      @global_context = Context::Global.new(**global_context)
      @metadata_context = Context::Metadata.new(**metadata_context)

      @specs = specs.map { |spec| Spec.new(**spec) }
    end
  end
end
