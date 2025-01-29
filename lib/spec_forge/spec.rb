# frozen_string_literal: true

module SpecForge
  class Spec
    #
    # Loads the specs from their yml files
    #
    # @param path [String, Path] The base path where the specs directory is located
    #
    def self.load_and_run(base_path)
      load_from_path(base_path.join("specs", "**/*.yml"))
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

    attr_reader :name, :path, :method, :params, :body, :expectations

    def initialize(name:, path:, method: "GET", params: {}, body: {}, expectations: [])
      @name = name
      @path = path
      @method = method
      @params = params
      @body = body
      @expectations = expectations
    end
  end
end
