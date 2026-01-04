# frozen_string_literal: true

module SpecForge
  class Forge
    class Request < Action
      def run(forge)
        sendable_request, resolved_request = build_requests

        forge.display.action(:request, "#{sendable_request.http_verb} #{sendable_request.url}", color: :yellow)

        response = forge.http_client.perform(sendable_request)

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
    end
  end
end
