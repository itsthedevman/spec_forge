# frozen_string_literal: true

module SpecForge
  class Step
    class Hook < Data.define(:callback_name, :arguments, :event)
      include Attribute::ToAttribute
    end
  end
end
