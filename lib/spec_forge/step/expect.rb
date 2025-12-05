# frozen_string_literal: true

module SpecForge
  class Step
    class Expect < Data.define(:name, :status, :headers, :raw, :json)
    end
  end
end
