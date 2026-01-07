# frozen_string_literal: true

module SpecForge
  module HTTP
    class Request < Struct.new(:base_url, :url, :http_verb, :headers, :query, :body)
      def initialize(**options)
        super(
          base_url: options[:base_url] || "",
          url: options[:url] || "",
          http_verb: Verb.from(options[:http_verb].presence || "GET"),
          headers: options[:headers] || {},
          query: options[:query] || {},
          body: options[:body] || {}
        )
      end

      def content_type
        headers["content-type"]
      end

      def json?
        content_type == "application/json"
      end

      def to_h
        super.tap do |h|
          h[:http_verb] = h[:http_verb].to_s
        end
      end
    end
  end
end
