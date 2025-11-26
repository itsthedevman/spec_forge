# frozen_string_literal: true

# {
#   # User stuff
#   name, debug, tags, documentation,
#   request, expect, store, hooks, call,

#   # System stuff
#   source: { file_name, line_number },
#   included_by: { file_name, line_number } | nil,
#   display_message: String | nil
# }
module SpecForge
  class Step < Data.define(
    :name, :debug, :tags, :documentation,
    :request, :expect, :store, :hooks,
    :call, :source, :included_by, :display_message
  )
    def initialize(**step)
      step[:debug] = step[:debug] == true

      step[:tags] ||= []
      step[:documentation] ||= {}
      step[:request] ||= {}
      step[:expect] ||= {}
      step[:store] ||= {}
      step[:hooks] ||= []
      step[:call] ||= []
      step[:source] ||= {}
      step[:included_by] ||= {}
      step[:display_message] ||= ""

      super(step)
    end
  end
end
