# frozen_string_literal: true

require_relative "spec/expectation"

module SpecForge
  class Spec
    #
    # Loads the specs from their yml files
    #
    # @param path [String, Path] The base path where the specs directory is located
    #
    def self.load_and_run(base_path)
      specs = load_from_path(base_path.join("specs", "**/*.yml"))

      failures = []

      specs.each do |spec|
        spec.compile!
        # spec.run!
      rescue => e
        failures << [spec, e]
      end

      # TODO: Handle failures
    end

    #
    # Loads any specs defined in the path. A single file can contain one or more specs
    #
    # @param path [String, Path] The path where the specs are located
    #
    # @return [Array<Spec>] An array of specs that were loaded.
    #
    def self.load_from_path(path)
      specs = []

      Dir[path].map do |file_path|
        hash = YAML.load_file(file_path).deep_symbolize_keys

        hash.each do |spec_name, spec_hash|
          spec_hash[:name] = spec_name

          specs << new(**spec_hash)
        end
      end

      specs
    end

    ############################################################################

    attr_reader :name, :expectations

    delegate :url, :http_method, :content_type, :params, :body, to: :@request

    def initialize(**options)
      @name = options[:name]
      @request = Request.new(**options)

      @expectations = (options[:expectations] || []).map { |e| Expectation.new(e) }
    end
  end

  def compile
    # Build the expectations, this can cause a failure
    # TODO: Handle errors
    @expectations.each_with_index { |e, i| e.compile!(self) }

    # Build the spec
  end
end
