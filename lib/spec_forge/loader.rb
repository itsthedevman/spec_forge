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
    # @param path [Pathname, nil] Specific path to load (defaults to blueprints/)
    # @param tags [Array<String>] Tags to include
    # @param skip_tags [Array<String>] Tags to exclude
    #
    # @return [Array<Blueprint>] Loaded blueprint objects
    #
    def self.load_blueprints(path: nil, tags: [], skip_tags: [])
      new(filter: {path:, tags:, skip_tags:}).load
    end

    def initialize(base_path: nil, filter: {})
      @base_path = base_path.present? ? Pathname.new(base_path) : SpecForge.forge_path.join("blueprints")
      @filter = filter
    end

    #
    # Loads and processes all blueprints
    #
    # @return [Array<Blueprint>] Processed blueprint objects
    #
    def load
      read_blueprints
        .index_by { |b| b[:name] }
        .then { |blueprints| StepProcessor.new(blueprints).run }
        .then { |blueprints| Filter.new(blueprints).run(**@filter) }
        .map { |b| Blueprint.new(**b) }
    end

    private

    def read_blueprints
      paths = Dir.glob(@base_path.join("**", "*.{yml,yaml}"))

      paths.map! do |file_path|
        file_path = Pathname.new(file_path)
        content = File.read(file_path)

        name = file_path.relative_path_from(@base_path).to_s
          .delete_suffix(".yml")
          .delete_suffix(".yaml")

        steps = parse_steps(content)

        {file_path:, name:, steps:}
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
