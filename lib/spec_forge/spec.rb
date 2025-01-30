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

    attr_reader :name, :path, :http_method, :content_type, :params, :body, :expectations

    def initialize(**options)
      @name = options[:name]
      @path = options[:path]
      @http_method = HTTPMethod.from(options[:method] || "GET")

      content_type = options[:content_type] || "application/json"
      @content_type = MIME::Types[content_type].first

      if @content_type.nil?
        raise ArgumentError, "Invalid content_type provided: #{content_type.inspect}"
      end

      # Params can only be a hash
      params = options[:params] || {}

      if !params.is_a?(Hash)
        raise TypeError, "Expected Hash, got #{params.class} for 'params'"
      end

      @params = params.transform_values { |v| Attribute.from(v) }

      # Body can support different types. Only supporting JSON and plain text right now
      @body =
        case @content_type
        when "application/json"
          body = options[:body] || {}
          raise TypeError, "Expected Hash, got #{body.class} for 'body'" if !body.is_a?(Hash)

          body.transform_values { |v| Attribute.from(v) }
        when "text/plain"
          Attribute.from(options[:body].to_s)
        end

      expectations = options[:expectations] || []
      @expectations = expectations.map { |e| Expectation.new(e) }
    end
  end
end
