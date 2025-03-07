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
      @specs = specs.map { |spec| Spec.new(**spec) }
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
      config = SpecForge.configuration.to_h.slice(:base_url, :headers, :query)

      specs.each_with_object({}) do |spec, hash|
        overlay = spec[:expectations].to_h do |expectation|
          [
            expectation[:id],
            expectation.extract!(*HTTP::REQUEST_ATTRIBUTES).reject { |_k, v| v.blank? }
          ]
        end

        overlay.reject! { |_k, v| v.blank? }

        base = spec.extract!(*HTTP::REQUEST_ATTRIBUTES)
        base = Configuration.overlay_options({http_verb: "GET", **config}, base)

        hash[spec[:id]] = {base:, overlay:}
      end
    end
  end
end
