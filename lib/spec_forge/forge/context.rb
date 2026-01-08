# frozen_string_literal: true

module SpecForge
  class Forge
    #
    # Holds the execution context for a forge run
    #
    # Context provides access to runtime state like variables that are
    # passed to callbacks and used during attribute resolution.
    #
    class Context < Data.define(:variables)
    end
  end
end
