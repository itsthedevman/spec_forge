# frozen_string_literal: true

module SpecForge
  class Step < Data.define(
    :name,
    :call,
    :debug,
    :description,
    :documentation,
    :expect,
    :hooks,
    :included_by,
    :request,
    :source,
    :store,
    :tags
  )
    #############################################################################
    class Source < Data.define(:file_name, :line_number)
    end

    class Hook < Data.define(:callback_name, :arguments, :event)
    end

    class Call < Data.define(:callback_name, :arguments)
    end

    attr_predicate :debug, :hooks, :call

    def initialize(**step)
      step[:call] = transform_call(step[:call])
      step[:debug] = step[:debug] == true
      step[:description] ||= nil
      step[:documentation] ||= nil
      step[:expect] ||= nil
      step[:hooks] = transform_hooks(step[:hooks])
      step[:included_by] = transform_source(step[:included_by])
      step[:request] ||= nil
      step[:source] = transform_source(step[:source])
      step[:store] ||= nil
      step[:tags] ||= nil

      super(step)
    end

    private

    def transform_source(source)
      return if source.blank?

      Source.new(file_name: source[:file_name], line_number: source[:line_number])
    end

    def transform_hooks(hooks)
      return if hooks.blank?

      hooks.flat_map(&:to_a).map do |event, hook|
        Hook.new(event:, callback_name: hook[:name], arguments: hook[:arguments])
      end
    end

    def transform_call(call)
      return if call.blank?

      Call.new(callback_name: call[:name], arguments: call[:arguments])
    end
  end
end
