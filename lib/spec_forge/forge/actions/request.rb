# frozen_string_literal: true

module SpecForge
  class Forge
    class Request < Action
      def run(forge)
        request = step.request

        forge.display.action(:request, "#{request.http_verb} #{request.url}", color: :yellow)

        response = forge.http_client.perform(request)

        forge.local_variables.store(:request, request)
        forge.local_variables.store(:response, response)
      end
    end
  end
end
