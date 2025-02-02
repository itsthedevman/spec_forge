# frozen_string_literal: true

require "httparty"

module SpecForge
  class HTTPClient
    class Adapter
      class HTTParty < Adapter
        include ::HTTParty

        def initialize(**options)
          adapter.base_uri(options[:base_url])
          adapter.format(HTTParty::Parser::SupportedFormats[options[:content_type].to_s])

          # Authorization header
          authorization = SpecForge.config.authorization[:default]
          adapter.headers(authorization[:header] => authorization[:value])
        end

        def adapter
          self.class
        end

        def delete(url, query: {}, body: {})
          adapter.delete(url, query:, body:)
        end

        def get(url, query: {}, body: {})
          adapter.get(url, query:, body:)
        end

        def patch(url, query: {}, body: {})
          adapter.patch(url, query:, body:)
        end

        def post(url, query: {}, body: {})
          adapter.post(url, query:, body:)
        end

        def put(url, query: {}, body: {})
          adapter.put(url, query:, body:)
        end
      end
    end
  end
end
