# frozen_string_literal: true

require_relative "loader/cache"

module SpecForge
  module Documentation
    #
    # Extracts API documentation data from SpecForge tests
    #
    # This class runs all tests and captures successful test contexts
    # to extract endpoint information, including request/response data.
    #
    # @example Extracting documentation data
    #   endpoints = Loader.extract_from_tests
    #
    class Loader
      #
      # Loads a documentation document with optional caching
      #
      # Extracts endpoint data from SpecForge tests, either from cache (if valid
      # and requested) or by running fresh tests. Returns a structured document
      # ready for generator consumption.
      #
      # @param use_cache [Boolean] Whether to use cached data if available
      #
      # @return [Document] Structured document containing endpoint data
      #
      def self.load_document(use_cache: false)
        cache = Cache.new

        endpoints =
          if use_cache && cache.valid?
            puts "Loading from cache..."
            cache.read
          else
            puts "Cache invalid - Regenerating..." if use_cache

            endpoints = extract_from_tests
            cache.create(endpoints)

            endpoints
          end

        Builder.document_from_endpoints(endpoints)
      end

      #
      # Runs tests and extracts endpoint data
      #
      # @return [Array<Hash>] Extracted endpoint data from successful tests
      #
      def self.extract_from_tests
        new
          .run_tests
          .extract_and_normalize_data
      end

      #
      # Initializes a new loader
      #
      # Sets up a unique callback and prepares storage for successful test results
      #
      # @return [Loader] A new loader instance
      #
      def initialize
        @callback_name = "__sf_docs_#{SpecForge.generate_id(self)}"
        @successes = []
      end

      #
      # Runs all tests and captures successful test results
      #
      # Registers a callback to capture test context and runs all tests
      #
      # @return [self] Returns self for method chaining
      #
      def run_tests
        @successes.clear

        Callbacks.register(@callback_name) do |context|
          next if context.expectation.documentation == false || context.spec.documentation == false

          @successes << context if context.example.execution_result.status == :passed
        end

        forges = prepare_forges

        Runner.run(forges, exit_on_finish: false, exit_on_failure: true)

        self
      ensure
        Callbacks.deregister(@callback_name)
      end

      #
      # Prepares forge objects for test execution
      #
      # Adds the documentation callback to each forge
      #
      # @return [Array<Forge>] Array of prepared forge objects
      #
      def prepare_forges
        forges = Runner.prepare

        forges.each do |forge|
          forge.global[:callbacks] << {after_each: @callback_name}
        end

        forges
      end

      #
      # Extracts and normalizes endpoint data from test results
      #
      # @return [Array<Hash>] Normalized endpoint data
      #
      def extract_and_normalize_data
        @successes.map { |d| extract_endpoint(d) }
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
