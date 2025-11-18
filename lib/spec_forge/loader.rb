# frozen_string_literal: true

module SpecForge
  class Loader
    def initialize(path: nil, tags: [], skip_tags: [])
      @path = path.present? ? Pathname.new(path) : SpecForge.forge_path.join("blueprints")
      @tags = tags
      @skip_tags = skip_tags
      @blueprints = prepare_blueprints
    end

    private

    def prepare_blueprints
      read_steps
        .then { |s| transform_steps(s) }
        .then { |b| create_blueprints(b) }
        .then { |b| filter_blueprints(b) }
    end

    def read_steps
      paths =
        if @path.directory?
          Dir[@path.join("**/*.yml")]
        else
          [@path.to_s]
        end

      paths.map do |file_path|
        [file_path, File.read(file_path)]
      end
    end

    def transform_steps(files)
      files.map! do |file_path, content|
        steps = YAML.safe_load(content, symbolize_names: true)

        {
          base_path: @path,
          file_path:,
          steps: normalize_steps(steps)
        }
      end
    end

    def normalize_steps(steps)
      steps.map! do |step|
        Normalizer.normalize!(step, using: :step)
      rescue => e
        raise Error::LoadStepError.new(e, step)
      end
    end

    def create_blueprints(blueprint_data)
      blueprint_data.map! { |d| Blueprint.new(**d) }
    end

    def filter_blueprints(blueprints)
      blueprints
    end
  end
end
