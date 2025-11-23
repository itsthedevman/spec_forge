# frozen_string_literal: true

module SpecForge
  STEP_ATTRIBUTES = %i[
    name
    line_number
    debug
    tags
    documentation
    request
    expect
    store
    hooks
    call
  ].freeze

  class Step < Data.define(*STEP_ATTRIBUTES)
    def initialize(**data)
      # Convert any sub-steps if they exist
      data[:steps].map! { |s| Step.new(**s) }

      super(data)
    end
  end
end
