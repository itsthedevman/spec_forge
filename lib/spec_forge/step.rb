# frozen_string_literal: true

module SpecForge
  class Step < Data.define(
    :name, :debug, :tags, :documentation,
    :request, :expect, :store, :hooks,
    :call, :source, :included_by, :description
  )
    class Source < Data.define(:file_name, :line_number)
    end

    class Hook < Data.define(:callback_name, :arguments, :event)
    end

    attr_predicate :debug, :hooks, :call

    def initialize(**step)
      step[:tags] ||= nil
      step[:documentation] ||= nil
      step[:request] ||= nil
      step[:expect] ||= nil
      step[:store] ||= nil
      step[:call] ||= nil
      step[:description] ||= nil

      step[:debug] = step[:debug] == true
      step[:source] = transform_source(step[:source])
      step[:included_by] = transform_source(step[:included_by])
      step[:hooks] = transform_hooks(step[:hooks])

      super(step)
    end

    private

    def transform_source(source)
      return if source.nil?

      Source.new(file_name: source[:file_name], line_number: source[:line_number])
    end

    def transform_hooks(hooks)
      return if hooks.nil?

      hooks.flat_map(&:to_a).map do |event, hook|
        Hook.new(event:, callback_name: hook[:name], arguments: hook[:arguments])
      end
    end
  end
end
