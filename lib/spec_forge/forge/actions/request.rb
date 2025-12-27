# frozen_string_literal: true

module SpecForge
  class Forge
    class Request < Action
      def run(forge)
        resolved_request = step.request.to_attribute.resolved

        request = resolved_request.dup
        request.body =
          if step.request.json?
            request.body.to_json
          else
            request.body.to_s
          end

        forge.display.action(:request, "#{request.http_verb} #{request.url}", color: :yellow)

        response = forge.http_client.perform(request)

        # Only store the original resolved request before we modify it
        forge.variables[:request] = resolved_request
        forge.variables[:response] = response
      end
    end
  end
end
