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

    attr_reader :name, :path, :method, :content_type, :params, :body, :expectations

    def initialize(**options)
      @name = options[:name]
      @path = options[:path] || "GET"
      @method = options[:method]

      @content_type = MIME::Types[options[:content_type] || "application/json"].first

      # Params can only be a hash
      @params = (options[:params] || {}).transform_values { |v| Attribute.from(v) }

      # Body can support different types. Only supporting JSON and plain text right now
      @body =
        case @content_type
        when "application/json"
          body = options[:body] || {}
          body.transform_values { |v| Attribute.from(v) }
        when "text/plain"
          Attribute.from(options[:body].to_s)
        end

      @expectations = options[:expectations] || []
    end
  end
end
