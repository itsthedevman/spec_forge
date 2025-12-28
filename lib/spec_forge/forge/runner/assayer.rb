# frozen_string_literal: true

module SpecForge
  class Forge
    class Runner
      class Assayer
        attr_reader :forge, :response

        def initialize(forge)
          @forge = forge
          @response = forge.variables[:response]
        end

        def response_status(rspec, matcher)
          rspec.expect(response.status).to matcher

          forge.display.success(HTTP.status_code_to_description(response.status), indent: 1)
        end

        def response_headers(rspec, headers_matcher)
          headers = response.headers

          headers_matcher.each do |key, matcher|
            rspec.expect(headers).to(rspec.have_key(key))
            rspec.expect(headers[key]).to(matcher)

            forge.display.success("#{key.in_quotes} #{matcher.description}", indent: 1)
          end
        end

        def response_json_size(rspec, matcher)
          rspec.expect(response.body.size).to matcher

          forge.display.success("Response size", indent: 1)
        end

        def response_json_structure(rspec, structure_matcher)
          check_json_structure(rspec, response.body.deep_stringify_keys, structure_matcher)

          forge.display.success("Response body structure", indent: 1)
        end

        private

        def check_json_structure(rspec, data, structure_matcher)
          case structure_matcher
          when Array # [Integer, String, [String], {id: String}]
            structure_matcher.each_with_index do |matcher, index|
              check_json_structure(rspec, data[index], matcher)
            end
          when Hash # {foo: String, bar: {baz: Integer}}
            structure_matcher.each do |key, matcher|
              rspec.expect(data).to(rspec.have_key(key))

              check_json_structure(rspec, data[key], matcher)
            end
          else # Class (String, Array, Integer, etc.)
            rspec.expect(data).to rspec.be_kind_of(structure_matcher)
          end
        end
      end
    end
  end
end
