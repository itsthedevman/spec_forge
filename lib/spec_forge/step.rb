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
    # @return [Boolean] Whether this step has a call action
    # @return [Boolean] Whether debug mode is enabled for this step
    # @return [Boolean] Whether this step registers callback hooks
    # @return [Boolean] Whether this step has expectations
    # @return [Boolean] Whether this step has a request action
    # @return [Boolean] Whether this step has store operations
    attr_predicate :call, :debug, :expect, :hooks, :request, :store

    #
    # Creates a new Step from the given attributes
    #
    # @param step [Hash] Step attributes from normalized YAML
    # @option step [String] :name The step name
    # @option step [Hash] :call Callback configuration
    # @option step [Boolean] :debug Whether debug mode is enabled
    # @option step [String] :description Step description
    # @option step [Hash] :documentation Documentation metadata
    # @option step [Array<Hash>] :expect Expectation definitions
    # @option step [Hash] :hooks Step-level event hooks for callbacks
    # @option step [Hash] :included_by Source of include if this step was included
    # @option step [Hash] :request Request configuration
    # @option step [Hash] :source Source file and line number
    # @option step [Hash] :store Variables to store
    # @option step [Array<String>] :tags Tags for filtering
    #
    # @return [Step] A new step instance
    #
    def initialize(**step)
      step[:call] = transform_calls(step[:call])
      step[:debug] = step[:debug] == true
      step[:description] ||= nil
      step[:documentation] ||= nil
      step[:expect] = transform_expect(step[:expect])
      step[:hooks] = transform_hooks(step[:hooks])
      step[:included_by] = transform_source(step[:included_by])
      step[:request] = transform_request(step[:request])
      step[:source] = transform_source(step[:source])
      step[:store] = transform_store(step[:store])
      step[:tags] ||= nil

      super(step)
    end

    # TODO: Use StepProcessor to rename :expects, and :calls
    alias_method :expects, :expect

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
