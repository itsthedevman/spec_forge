# frozen_string_literal: true

module SpecForge
  class Step < Data.define(
    :name,
    :call,
    :debug,
    :description,
    :documentation,
    :expect,
    :included_by,
    :request,
    :source,
    :store,
    :tags
  )
    attr_predicate :debug, :call, :request, :expect, :store

    def initialize(**step)
      step[:call] = transform_call(step[:call])
      step[:debug] = step[:debug] == true
      step[:description] ||= nil
      step[:documentation] ||= nil
      step[:expect] ||= transform_expect(step[:expect])
      step[:included_by] = transform_source(step[:included_by])
      step[:request] = transform_request(step[:request])
      step[:source] = transform_source(step[:source])
      step[:store] = transform_store(step[:store])
      step[:tags] ||= nil

      super(step)
    end

    alias_method :expects, :expect

    private

    def transform_source(source)
      return if source.blank?

      Source.new(file_name: source[:file_name], line_number: source[:line_number])
    end

    def transform_call(call)
      return if call.blank?

      Call.new(callback_name: call[:name], arguments: call[:arguments])
    end

    def transform_request(request)
      return if request.blank?

      HTTP::Request.new(**request)
    end

    def transform_expect(expects)
      return if expects.blank?

      expects.map { |e| Expect.new(**e) }
    end

    def transform_store(store)
      store.presence
    end
  end
end
