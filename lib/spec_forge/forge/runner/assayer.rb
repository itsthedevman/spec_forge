# frozen_string_literal: true

module SpecForge
  class Forge
    class Runner
      class Assayer
        attr_reader :forge, :display

        def initialize(forge)
          @forge = forge
          @display = forge.display
          @response = forge.variables[:response]
          @headers = @response.headers
          @body = normalize_body(@response.body)
        end

        def response_status(rspec, matcher)
          rspec.expect(@response.status).to matcher

          display.success("Status", indent: 1)
        end

        def response_headers(rspec, headers_matcher)
          headers_matcher.each do |key, matcher|
            rspec.expect(@headers).to(rspec.have_key(key))
            rspec.expect(@headers[key]).to(matcher)
          end

          display.success("Headers", indent: 1)
        end

        def response_json_size(rspec, matcher)
          rspec.expect(@body.size).to matcher
          display.success("Size", indent: 1)
        end

        def response_json_shape(rspec, structure)
          failures = ShapeValidator.new(rspec, @body, structure).validate

          if failures.size == 0
            display.success("Shape", indent: 1)
          else
            raise Error::ShapeValidationFailure.new(failures)
          end
        end

        private

        def normalize_body(body)
          body.is_a?(Hash) ? body.deep_stringify_keys : body
        end
      end
    end
  end
end
