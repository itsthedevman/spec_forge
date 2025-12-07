# frozen_string_literal: true

module SpecForge
  class Step
    class Call < Data.define(:callback_name, :arguments)
      include Attribute::ToAttribute
    end
  end
end
