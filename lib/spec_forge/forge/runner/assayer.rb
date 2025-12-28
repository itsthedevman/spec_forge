# frozen_string_literal: true

module SpecForge
  class Forge
    class Runner
      class Assayer
        attr_reader :forge, :display, :response

        def initialize(forge)
          @forge = forge

          @display = forge.display
          @response = forge.variables[:response]

          @headers = response.headers
          @body = response.body

          @body = @body.deep_stringify_keys if @body.is_a?(Hash)
        end

        def response_status(rspec, matcher)
          rspec.expect(response.status).to matcher

          display.success(HTTP.status_code_to_description(response.status), indent: 1)
        end

        def response_headers(rspec, headers_matcher)
          headers_matcher.each do |key, matcher|
            rspec.expect(@headers).to(rspec.have_key(key))
            rspec.expect(@headers[key]).to(matcher)

            display.success("#{key.in_quotes} #{matcher.description}", indent: 1)
          end
        end

        def response_json_size(rspec, matcher)
          rspec.expect(@body.size).to matcher

          display.success("Response size", indent: 1)
        end

        def response_json_shape(rspec, shape_matcher)
          check_json_structure(rspec, @body, shape_matcher)

          display.success("Response body shape", indent: 1)
        end

        private

        def check_json_structure(rspec, data, structure)
          case structure
          when Array # [Integer, String, [String], {id: String}]
            check_json_array(rspec, data, structure)
          when Hash # {foo: String, bar: {baz: Integer}}
            check_json_object(rspec, data, structure)
          else # Class (String, Array, Integer, etc.)
            puts "#{data.inspect} is expected to be kind of #{structure}"
            rspec.expect(data).to rspec.be_kind_of(structure)
          end
        end

        def check_json_array(rspec, data, structure)
          structure.each_with_index do |matcher, index|
            check_json_structure(rspec, data[index], matcher)
          rescue RSpec::Expectations::ExpectationNotMetError => e
            e.message.insert(0, "Index: #{index}\n")
            raise e
          end
        end

        def check_json_object(rspec, data, structure)
          structure.each do |key, matcher|
            rspec.expect(data).to(rspec.have_key(key))

            check_json_structure(rspec, data[key], matcher)
          rescue RSpec::Expectations::ExpectationNotMetError => e
            e.message.insert(0, "Key: #{key.in_quotes}\n")
            raise e
          end
        end
      end
    end
  end
end
