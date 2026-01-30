# frozen_string_literal: true

module SpecForge
  #
  # Loads and processes blueprint YAML files into executable Blueprint objects
  #
  # The Loader handles the load-time phase of SpecForge, reading YAML files,
  # parsing steps with line numbers, expanding includes, flattening hierarchies,
  # and applying filters.
  #
  class Loader
    #
    # Loads blueprints from disk with optional filtering
    #
    # @param base_path [Pathname, String, nil] Base directory for glob loading (defaults to blueprints/)
    # @param paths [Array<Pathname, String>] Specific file paths to load (no globbing)
    # @param tags [Array<String>] Tags to include
    # @param skip_tags [Array<String>] Tags to exclude
    #
    # @return [Array<Blueprint>, Hash] Loaded blueprint objects and any forge hooks
    #
    def self.load_blueprints(base_path: nil, paths: [], tags: [], skip_tags: [])
      new(base_path:, paths:, filter: {tags:, skip_tags:}).load
    end

    #
    # Creates a new Loader with the specified base path and filter options
    #
    # @param base_path [Pathname, String, nil] Base directory for glob loading (defaults to blueprints/)
    # @param paths [Array<Pathname, String>] Specific file paths to load (no globbing)
    # @param filter [Hash] Filter options for tags and skip_tags
    #
    # @return [Loader] A new loader instance
    #
    def initialize(base_path: nil, paths: [], filter: {})
      @base_path = base_path.present? ? Pathname.new(base_path) : SpecForge.forge_path.join("blueprints")
      @paths = Array.wrap(paths).map { |p| Pathname.new(p) }
      @filter = filter
    end

    #
    # Loads and processes all blueprints, extracting any hook data at the same time
    #
    # @return [Array<Blueprint>, Hash] Loaded blueprint objects and any forge hooks
    #
    def load
      blueprints, forge_hooks = read_blueprints
        .index_by { |b| b[:name] }
        .then { |blueprints| StepProcessor.new(blueprints).run }

      blueprints = Filter.new(blueprints).run(**@filter).map { |b| Blueprint.new(**b) }

      [blueprints, forge_hooks]
    end

    private

    def read_blueprints
      # Use specific paths if provided, otherwise glob from base_path
      file_paths =
        if @paths.present?
          @paths
        else
          Dir.glob(@base_path.join("**", "*.{yml,yaml}")).map { |p| Pathname.new(p) }
        end

      file_paths.map do |file_path|
        content = File.read(file_path)

        # Determine the relative path for naming
        relative_path =
          if @paths.present?
            # For specific paths, use the filename as the base
            file_path.basename
          else
            # For glob loading, use path relative to base_path
            file_path.relative_path_from(@base_path)
          end

        name = relative_path.to_s.delete_suffix(".yml").delete_suffix(".yaml")
        steps = parse_steps(content)

        {file_path: relative_path, name:, steps:}
      end
    end

    def parse_steps(content)
      # Parse with Psych to make it easier to extract line numbers
      yaml = Psych.parse(content)

      steps = yaml.to_ruby(symbolize_names: true)
      inject_line_numbers(yaml.root, steps)
    end

    def inject_line_numbers(yaml_node, ruby_object)
      case ruby_object
      when Array
        inject_line_numbers_into_array(yaml_node, ruby_object)
      when Hash
        inject_line_numbers_into_hash(yaml_node, ruby_object)
      else
        ruby_object
      end
    end

    def inject_line_numbers_into_array(yaml_node, array)
      yaml_node.children
        .map
        .with_index { |node, index| inject_line_numbers(node, array[index]) }
    end

    def inject_line_numbers_into_hash(yaml_node, hash)
      # Psych uses 0-indexed line numbers
      hash[:line_number] = yaml_node.start_line + 1

      # Walk through key-value pairs in the YAML tree
      yaml_node.children.each_slice(2) do |key_node, value_node|
        key = key_node.value.to_sym

        # Only recursively add line numbers to substeps.
        next unless key == :steps

        hash[key] = inject_line_numbers(value_node, hash[key])
      end

      hash
    end
  end
end
