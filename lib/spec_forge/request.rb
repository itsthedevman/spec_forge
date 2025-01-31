# frozen_string_literal: true

module SpecForge
  class Request < Data.define(:url, :http_method, :content_type, :params, :body)
    def self.normalize_body(content_type, body)
      # Body can support different types. Only supporting JSON and plain text right now
      case content_type
      when "application/json"
        if !body.is_a?(Hash)
          raise InvalidTypeError.new(body, Hash, for: "'body'")
        end

        body.transform_values { |v| Attribute.from(v) }
      when "text/plain"
        Attribute.from(body.to_s)
      end
    end

    def initialize(**options)
      url = options[:path] || options[:url]

      http_method = options[:method] || options[:http_method] || "GET"
      http_method = HTTPMethod.from(http_method)

      content_type = options[:content_type] || "application/json"
      content_type = MIME::Types[content_type].first

      if content_type.nil?
        raise ArgumentError, "Invalid content_type provided: #{content_type.inspect}"
      end

      # Params can only be a hash
      params = options[:params] || {}
      if !params.is_a?(Hash)
        raise InvalidTypeError.new(params, Hash, for: "'params'")
      end

      params.transform_values! { |v| Attribute.from(v) }
      body = self.class.normalize_body(content_type, options[:body] || {})

      super(url:, http_method:, content_type:, params:, body:)
    end
  end
end
