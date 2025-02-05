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
      specs.each(&:run)
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
          spec_hash[:file_path] = file_path

          specs << new(**spec_hash)
        end
      end

      specs
    end

    ############################################################################

    attr_reader :name, :file_path, :expectations

    def initialize(**input)
      @name = input.delete(:name)
      @file_path = input.delete(:file_path)

      input = Normalizer.normalize(input)
      global_options = input.except(:expectations)

      @expectations =
        input[:expectations].map.with_index do |expectation_input, index|
          Expectation.new(
            "expectations (item #{index})",
            expectation_input,
            global_options:
          )
        end
    end

    def run
      Runner.new(self).run
    end
  end
end
