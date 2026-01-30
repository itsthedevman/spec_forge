# frozen_string_literal: true

module SpecForge
  class Forge
    #
    # Action for the `request:` step attribute
    #
    # Builds and executes an HTTP request based on the step's configuration,
    # then stores both the request and response in the forge's variables for
    # use by subsequent actions.
    #
    class Request < Action
      #
      # Executes the HTTP request and stores the response
      #
      # @param forge [Forge] The forge instance
      #
      # @return [void]
      #
      def run(forge)
        sendable_request, resolved_request = build_requests

        forge.display.action(
          "#{sendable_request.http_verb} #{sendable_request.url}",
          symbol: :right_arrow, symbol_styles: :yellow
        )

        response = forge.http_client.perform(sendable_request)
        response = parse_response(response)

        # Only store the original resolved request before we modify it
        forge.variables[:request] = resolved_request
        forge.variables[:response] = response
      end

      private

      def build_requests
        resolved_request = step.request.to_h.transform_values { |v| v.respond_to?(:resolved) ? v.resolved : v }
        resolved_request[:base_url] = SpecForge.configuration.base_url if resolved_request[:base_url].blank?

        request = resolved_request.deep_dup
        request[:body] =
          if step.request.json?
            request[:body].to_json
          else
            request[:body].to_s
          end

        [HTTP::Request.new(**request), resolved_request]
      end

      def parse_response(response)
        response.to_hash.tap do |response|
          response[:headers] = response.delete(:response_headers)

          case response[:headers]["content-type"]
          when "application/json"
            response[:body] = response[:body].to_h
          end
        end
      end
    end
  end
end
