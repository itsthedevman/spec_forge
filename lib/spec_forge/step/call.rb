# frozen_string_literal: true

module SpecForge
  class Step
    #
    # Represents a callback invocation within a step
    #
    # Holds the callback name and any arguments to pass when the
    # callback is executed during step processing.
    #
    class Call < Data.define(:callback_name, :arguments)
    end
  end
end
