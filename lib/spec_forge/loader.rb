# frozen_string_literal: true

module SpecForge
  class Loader < Data.define(:path, :blueprints)
    def initialize(path: nil, tags: [], skip_tags: [])
      path = path.present? ? Pathname.new(path) : SpecForge.forge_path.join("blueprints")
      blueprints = load_blueprints(path, tags:, skip_tags:)

      super(path:, blueprints:)
    end

    private

    def load_blueprints(path, tags: [], skip_tags: [])
      read_blueprints(path)
        .index_by { |b| b[:name] }
        .then { |blueprints| StepProcessor.new(blueprints, tags:, skip_tags:).run }
        .values
        .map { |d| Blueprint.new(**d) }
    end

    def read_blueprints(path)
      paths =
        if path.directory?
          Dir.glob(path.join("**/*.{yml,yaml}"))
        else
          [path.to_s]
        end

      paths.map! do |file_path|
        file_path = Pathname.new(file_path)
        content = File.read(file_path)

        relative_path = file_path.relative_path_from(path)
        name = relative_path.to_s.delete_suffix(".yml").delete_suffix(".yaml")

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
        hash[key] = inject_line_numbers(value_node, hash[key])
      end

      hash
    end
  end
end
