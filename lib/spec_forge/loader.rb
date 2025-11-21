# frozen_string_literal: true

module SpecForge
  class Loader < Data.define(:path, :tags, :skip_tags, :blueprints)
    def initialize(path: nil, tags: [], skip_tags: [])
      tags ||= []
      skip_tags ||= []

      path = path.present? ? Pathname.new(path) : SpecForge.forge_path.join("blueprints")
      blueprints = prepare_blueprints(path, tags, skip_tags)

      super(path:, tags:, skip_tags:, blueprints:)
    end

    private

    def prepare_blueprints(path, tags, skip_tags)
      read_steps(path)
        .then { |s| transform_steps(s, path) }
        .then { |b| create_blueprints(b) }
        .then { |b| filter_blueprints(b, tags, skip_tags) }
    end

    def read_steps(path)
      paths =
        if path.directory?
          Dir[path.join("**/*.yml")]
        else
          [path.to_s]
        end

      paths.map do |file_path|
        [Pathname.new(file_path), File.read(file_path)]
      end
    end

    def transform_steps(files, base_path)
      files.map! do |file_path, content|
        # Parse with Psych to get line numbers
        yaml_tree = Psych.parse(content)
        steps = yaml_tree.to_ruby(symbolize_names: true)

        # Inject line numbers into each step
        steps = inject_line_numbers(yaml_tree.root, steps)

        {
          base_path:,
          file_path:,
          steps: normalize_steps(steps)
        }
      end
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
      yaml_node.children.map.with_index do |child_node, index|
        inject_line_numbers(child_node, array[index])
      end
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

    def normalize_steps(steps, depth = 0)
      max_depth = SpecForge::Normalizer::Structure::MAX_DEPTH

      steps.map do |step|
        if depth >= max_depth && step[:steps].present?
          raise Error::MaxDepthError.new(depth + 1, max: max_depth)
        end

        step = Normalizer.normalize!(step, using: :step)

        if step[:steps].present?
          step[:steps] = normalize_steps(step[:steps], depth + 1)
        end

        step
      rescue => e
        raise Error::LoadStepError.new(e, step, depth)
      end
    end

    def create_blueprints(blueprint_data)
      blueprint_data.map! { |d| Blueprint.new(**d) }
    end

    def filter_blueprints(blueprints, tags, skip_tags)
      blueprints
    end
  end
end
