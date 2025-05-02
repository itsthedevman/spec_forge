# frozen_string_literal: true

module SpecForge
  #
  # Represents a collection of related specs loaded from a single YAML file
  #
  # A Forge contains multiple specs with their expectations, global variables,
  # and request configuration. It acts as the container for all tests defined
  # in a single file and manages their shared context.
  #
  # @example Creating a forge
  #   global = {variables: {api_key: "123"}}
  #   metadata = {file_name: "users", file_path: "/path/to/users.yml"}
  #   specs = [{name: "list_users", url: "/users", expectations: [...]}]
  #   forge = Forge.new(global, metadata, specs)
  #
  class Forge
    #
    # The name of this forge from the relative path
    #
    # @return [String] The name derived from the file path
    #
    attr_reader :name

    #
    # Global variables and configuration shared across all specs
    #
    # @return [Hash] The global variables and configuration
    #
    attr_reader :global

    #
    # Metadata about the spec file
    #
    # @return [Hash] File information such as path and name
    #
    attr_reader :metadata

    #
    # Variables defined at the spec and expectation levels
    #
    # @return [Hash] Variable definitions organized by spec
    #
    attr_reader :variables

    #
    # Request configuration for the specs
    #
    # @return [Hash] HTTP request configuration by spec
    #
    attr_reader :request

    #
    # Collection of specs contained in this forge
    #
    # @return [Array<Spec>] The specs defined in this file
    #
    attr_accessor :specs

    #
    # Creates a new Forge instance containing specs from a YAML file
    #
    # @param global [Hash] Global variables shared across all specs in the file
    # @param metadata [Hash] Information about the spec file
    # @param specs [Array<Hash>] Array of spec definitions from the file
    #
    # @return [Forge] A new forge instance with the processed specs
    #
    def initialize(global, metadata, specs)
      @name = metadata[:relative_path]

      @global = global
      @metadata = metadata

      @variables = extract_variables!(specs)
      @request = extract_request!(specs)
      @specs = specs.map { |spec| Spec.new(**spec) }
    end

    #
    # Retrieves variables for a specific spec
    #
    # Returns the variables defined for a specific spec, including
    # both base variables and any overlay variables for its expectations.
    #
    # @param spec [Spec] The spec to get variables for
    #
    # @return [Hash] The variables for the spec
    #
    def variables_for_spec(spec)
      @variables[spec.id]
    end

    private

    #
    # Extracts variables from specs and organizes them into base and overlay variables
    #
    # @param specs [Array<Hash>] Array of spec definitions
    #
    # @return [Hash] A hash mapping spec IDs to their variables
    #
    # @private
    #
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

    #
    # Extracts request configuration from specs and organizes them into base and overlay configs
    #
    # @param specs [Array<Hash>] Array of spec definitions
    #
    # @return [Hash] A hash mapping spec IDs to their request configurations
    #
    # @private
    #
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
        base.reject! { |_k, v| v.blank? }

        base = config.deep_merge(base)
        base[:http_verb] ||= "GET"

        hash[spec[:id]] = {base:, overlay:}
      end
    end
  end
end
