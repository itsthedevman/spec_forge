# frozen_string_literal: true

module SpecForge
  class Step
    class Hook < Data.define(:callback_name, :arguments, :event)
    end
  end
end
