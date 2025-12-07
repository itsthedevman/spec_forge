# frozen_string_literal: true

module SpecForge
  class Forge
    class Request < Action
      def run(forge)
        request = step.request.to_attribute.resolved

        forge.display.action(:request, "#{request.http_verb} #{request.url}", color: :yellow)

        response = forge.http_client.perform(request)

        forge.variables[:request] = request
        forge.variables[:response] = response
      end
    end
  end
end
