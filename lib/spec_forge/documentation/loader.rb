# frozen_string_literal: true

module SpecForge
  module Documentation
    class Loader
      include Singleton

      def self.load
        instance
          .run
          .normalize
      end

      def initialize
        @callback_name = "__sf_docs_#{SpecForge.generate_id(self)}"
        @successes = []
      end

      def run
        forges = setup
        Runner.run(forges, exit_on_finish: false)

        self
      ensure
        teardown
      end

      def setup
        @successes.clear

        forges = Runner.prepare

        forges.each do |forge|
          forge.global[:callbacks] << {after_each: @callback_name}
        end

        Callbacks.register(@callback_name) do |context|
          @successes << context if context.example.execution_result.status == :passed
        end

        forges
      end

      def teardown
        Callbacks.deregister(@callback_name)
      end

      def normalize
        object = {endpoints: [], structures: []}

        @successes.each_with_object(object) do |context, hash|
          hash[:endpoints] << extract_endpoint(context)
        end
      end

      private

      def extract_endpoint(context)
        request_hash = context.request.to_h
        response_hash = context.response.to_hash

        # Only pull the headers that the user explicitly checked for.
        # This keeps the extra unrelated headers from being included
        response_headers = context.expectation
          .constraints
          .headers
          .keys
          .map { |h| h.to_s.downcase }

        response_headers = response_hash[:response_headers].slice(*response_headers)

        {
          # Metadata
          spec_name: context.spec.name,
          expectation_name: context.expectation.name,

          # Request data
          base_url: request_hash[:base_url],
          url: request_hash[:url],
          http_verb: request_hash[:http_verb],
          content_type: request_hash[:content_type],
          request_body: request_hash[:body],
          request_headers: request_hash[:headers],
          request_query: request_hash[:query],

          # Response data
          response_status: response_hash[:status],
          response_body: response_hash[:body],
          response_headers:
        }
      end
    end
  end
end
