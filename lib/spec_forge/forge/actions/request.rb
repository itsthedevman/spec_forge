# frozen_string_literal: true

module SpecForge
  class Forge
    class Request < Action
      def run(forge)
        resolved_request = step.request.to_attribute.resolved

        # Do not store the request that contains the converted body data
        request = resolved_request.dup
        request.body =
          if step.request.json?
            request.body.to_json
          else
            request.body.to_s
          end

        forge.display.action(:request, "#{request.http_verb} #{request.url}", color: :yellow)

        response = forge.http_client.perform(request)

        forge.variables[:request] = resolved_request
        forge.variables[:response] = response
      end
    end
  end
end
