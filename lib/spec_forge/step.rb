# frozen_string_literal: true

module SpecForge
  STEP_ATTRIBUTES = %i[
    name
    verbose
    debug
    tags
    documentation
    request
    expect
    store
    hooks
    call
    steps
    include
  ].freeze

  class Step < Data.define(*STEP_ATTRIBUTES)
  end
end
