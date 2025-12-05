# frozen_string_literal: true

module SpecForge
  class Step
    class Call < Data.define(:callback_name, :arguments)
    end
  end
end
