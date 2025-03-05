# frozen_string_literal: true

module SpecForge
  class Forge
    attr_reader :name, :global, :metadata, :specs, :variables, :request
    attr_writer :specs

    def initialize(global, metadata, specs)
      @name = metadata[:relative_path]

      @global = global
      @metadata = metadata

      @variables = extract_variables!(specs)
      @request = extract_request!(specs)
      @specs = load_specs(specs)
    end

    def variables_for_spec(spec)
      @variables[spec.id]
    end

    private

    def extract_variables!(specs)
      #
      # Creates a hash that looks like this:
      #
      # {
      #   spec_1: {
      #     base: {var_1: true, var_2: false},
      #     overlay: {
      #       expectation: {var_1: false}
      #     }
      #   },
      #   spec_2: ...
      # }
      #
      specs.each_with_object({}) do |spec, hash|
        overlay = spec[:expectations].to_h { |e| [e[:id], e.delete(:variables)] }
          .reject { |_k, v| v.blank? }

        hash[spec[:id]] = {base: spec.delete(:variables), overlay:}
      end
    end

    def extract_request!(specs)
      #
      # Creates a hash that looks like this:
      #
      # {
      #   spec_1: {
      #     base: {base_url: "https://foo.bar", url: "", ...},
      #     overlay: {
      #       expectation: {base_url: "https://bar.baz", ...}
      #     }
      #   },
      #   spec_2: ...
      # }
      #
      request_attributes = [:base_url, :url, :http_verb, :headers, :query, :body]
      config = SpecForge.configuration.to_h.slice(:base_url, :headers, :query)

      specs.each_with_object({}) do |spec, hash|
        overlay = spec[:expectations].to_h do |expectation|
          [
            expectation[:id],
            expectation.extract!(*request_attributes).reject { |_k, v| v.blank? }
          ]
        end

        overlay.reject! { |_k, v| v.blank? }

        base = spec.extract!(*request_attributes)
        base = Configuration.overlay_options({http_verb: "GET", **config}, base)

        hash[spec[:id]] = {base:, overlay:}
      end
    end

    def load_specs(specs)
      specs.map do |spec|
        request = @request[spec[:id]]
        base_request_data = request[:base].slice(:http_verb, :url)

        # Generate the name to each expectation
        spec[:expectations].each do |expectation|
          # If the expectation has an overlay, use it.
          request_data = request.dig(:overlay, expectation[:id])
            &.slice(:http_verb, :url)
            .presence

          # Overwise, default to the base request
          request_data ||= base_request_data

          expectation[:name] = generate_expectation_name(
            name: expectation[:name],
            **request_data
          )
        end

        Spec.new(**spec)
      end
    end

    def generate_expectation_name(http_verb:, url:, name: nil)
      base = "#{http_verb.upcase} #{url}"   # GET /users
      base += " - #{name}" if name.present? # GET /users - Returns 404 because y not?
      base
    end
  end
end
