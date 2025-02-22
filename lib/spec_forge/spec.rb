# frozen_string_literal: true

require_relative "spec/expectation"

module SpecForge
  class Spec
    #
    # Loads and defines specs with the runner. Specs can be filtered using the optional parameters
    #
    # @param file_name [String, nil] The name of the file without the extension.
    # @param spec_name [String, nil] The name of the spec in a yaml file
    # @param expectation_name [String, nil] The name of the expectation for a spec.
    #
    # @return [Array<Spec>]
    #
    def self.load_and_define(file_name: nil, spec_name: nil, expectation_name: nil)
      specs = load_from_files

      filter_specs(specs, file_name:, spec_name:, expectation_name:)

      # Announce if we're using a filter
      if file_name
        filter = {file_name:, spec_name:, expectation_name:}.delete_if { |k, v| v.blank? }
        filter.stringify_keys!
        puts "Using filter: #{filter}"
      end

      specs.each(&:define)
    end

    #
    # Loads any specs defined in the spec files. A single file can contain one or more specs
    #
    # @return [Array<Spec>] An array of specs that were loaded.
    #
    def self.load_from_files
      path = SpecForge.forge.join("specs")
      specs = []

      Dir[path.join("**/*.yml")].each do |file_path|
        content = File.read(file_path)
        hash = YAML.load(content).deep_symbolize_keys

        hash.each do |spec_name, spec_hash|
          line_number = content.lines.index { |line| line.start_with?("#{spec_name}:") }

          spec_hash[:name] = spec_name.to_s
          spec_hash[:file_path] = file_path
          spec_hash[:file_name] = file_path.delete_prefix("#{path}/").delete_suffix(".yml")
          spec_hash[:line_number] = line_number ? line_number + 1 : -1

          specs << new(**spec_hash)
        end
      end

      specs
    end

    # @private
    def self.filter_specs(specs, file_name: nil, spec_name: nil, expectation_name: nil)
      # Guard against invalid partial filters
      if expectation_name && spec_name.blank?
        raise ArgumentError, "The spec's name is required when filtering by an expectation's name"
      end

      if spec_name && file_name.blank?
        raise ArgumentError, "The spec's filename is required when filtering by a spec's name"
      end

      specs.select! { |spec| spec.file_name == file_name } if file_name
      specs.select! { |spec| spec.name == spec_name } if spec_name

      if expectation_name
        specs.each do |spec|
          spec.expectations.select! { |expectation| expectation.name == expectation_name }
        end
      end

      specs
    end

    ############################################################################

    attr_predicate :debug

    attr_reader :name, :file_path, :file_name, :line_number, :expectations

    #
    # Creates a Spec based on the input
    #
    # @param name [String] The identifier for this spec
    # @param file_path [String] The path where this spec is defined
    # @param **input [Hash] Any attributes related to the spec, including expectations
    #   See Normalizer::Spec
    #
    def initialize(name:, file_path:, file_name:, line_number:, **input)
      @name = name
      @file_path = file_path
      @file_name = file_name
      @line_number = line_number

      input = Normalizer.normalize_spec!(input)

      # Don't pass this down to the expectations
      @debug = input.delete(:debug) || false

      global_options = normalize_global_options(input)

      @expectations =
        input[:expectations].map.with_index do |expectation_input, index|
          Expectation.new(expectation_input, global_options:)
        end
    end

    def define
      Runner.define_spec(self)
    end

    private

    def normalize_global_options(input)
      config = SpecForge.configuration.to_h.slice(:base_url, :headers, :query)
      Configuration.overlay_options(config, input.except(:expectations))
    end
  end
end
