# frozen_string_literal: true

module SpecForge
  class Config < Struct.new
    include Singleton

    def initialize
      defaults = Normalizer.default_config
    end
  end
end
