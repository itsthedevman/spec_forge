# frozen_string_literal: true

module SpecForge
  class Forge
    class Request < Action
      def run(forge)
        request = step.request
        response = forge.http_client.perform(request)

        forge.local_variables.store(:request, request)
        forge.local_variables.store(:response, response)
      end
    end
  end
end
