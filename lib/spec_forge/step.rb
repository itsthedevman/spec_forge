# frozen_string_literal: true

module SpecForge
  class Step < Data.define(
    :name, :debug, :tags, :documentation,
    :request, :expect, :store, :hooks,
    :call, :source, :included_by, :description
  )
    def initialize(**step)
      step[:tags] ||= []
      step[:documentation] ||= {}
      step[:request] ||= {}
      step[:expect] ||= {}
      step[:store] ||= {}
      step[:hooks] ||= []
      step[:call] ||= []
      step[:description] ||= ""

      step[:debug] = step[:debug] == true
      step[:source] = (step[:source] || {}).to_istruct
      step[:included_by] = (step[:included_by] || {}).to_istruct

      super(step)
    end
  end
end
