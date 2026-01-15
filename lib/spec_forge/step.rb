# frozen_string_literal: true

module SpecForge
  #
  # Represents a single executable step within a blueprint
  #
  # Steps are the fundamental unit of execution in SpecForge. Each step
  # can contain a request, expectations, store operations, callbacks,
  # and debug triggers. Steps are immutable value objects created from
  # normalized YAML data.
  #
  class Step < Data.define(
    :name,
    :calls,
    :debug,
    :description,
    :documentation,
    :expects,
    :hooks,
    :included_by,
    :request,
    :source,
    :store,
    :tags
  )
    # @return [Boolean] Whether this step uses callbacks
    # @return [Boolean] Whether debug mode is enabled for this step
    # @return [Boolean] Whether this step registers callback hooks
    # @return [Boolean] Whether this step has expectations
    # @return [Boolean] Whether this step has a request action
    # @return [Boolean] Whether this step has store operations
    attr_predicate :calls, :debug, :expects, :hooks, :request, :store

    # TODO: Documentation
    def initialize(**step)
      step[:calls] = transform_calls(step[:calls])
      step[:debug] = step[:debug] == true
      step[:description] ||= nil
      step[:documentation] ||= nil
      step[:expects] = transform_expect(step[:expects])
      step[:hooks] = transform_hooks(step[:hooks])
      step[:included_by] = transform_source(step[:included_by])
      step[:request] = transform_request(step[:request])
      step[:source] = transform_source(step[:source])
      step[:store] = transform_store(step[:store])
      step[:tags] ||= nil

      super(step)
    end

    private

    def transform_source(source)
      return if source.blank?

      Source.new(file_name: source[:file_name], line_number: source[:line_number])
    end

    def transform_calls(calls)
      return if calls.blank?

      calls.map { |call| Call.new(callback_name: call[:name], arguments: call[:arguments]) }
    end

    def transform_request(input)
      return if input.blank?

      request = {}

      if (url = input[:base_url]) && url.present?
        request[:base_url] = Attribute.from(url)
      end

      if (url = input[:url]) && url.present?
        request[:url] = Attribute.from(url)
      end

      if (verb = input[:http_verb]) && verb.present?
        request[:http_verb] = verb
      end

      headers = (input[:headers] || {}).transform_keys(&:downcase)

      if input[:json].present?
        headers["content-type"] ||= "application/json"
      elsif headers.present?
        headers["content-type"] ||= "text/plain"
      end

      if headers.present?
        request[:headers] = Attribute.from(headers)
      end

      if (query = input[:query]) && query.present?
        request[:query] = Attribute.from(query)
      end

      if (json = input[:json]) && json.present?
        request[:body] = Attribute.from(json)
      elsif (raw = input[:raw]) && raw.present?
        request[:body] = Attribute.from(raw)
      end

      HTTP::Request.new(**request)
    end

    def transform_expect(expects)
      return if expects.blank?

      expects.map { |e| Expect.new(**e) }
    end

    def transform_store(store)
      return if store.blank?

      store.transform_values { |v| Attribute.from(v) }
    end

    def transform_hooks(hooks)
      hooks = hooks&.compact_blank
      return if hooks.blank?

      hooks.transform_values do |call|
        Array.wrap(call).map { |c| Call.new(callback_name: c[:name], arguments: c[:arguments]) }
      end
    end
  end
end
