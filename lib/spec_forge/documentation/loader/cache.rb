# frozen_string_literal: true

module SpecForge
  module Documentation
    class Loader
      class Cache
        def initialize
          @endpoint_cache = SpecForge.openapi_path.join("generated", ".cache", "endpoints.yml")
          @spec_cache = SpecForge.openapi_path.join("generated", ".cache", "specs.yml")
        end

        def valid?
          endpoint_cache? && !specs_updated?
        end

        def create(endpoints)
          write_spec_cache
          write(endpoints)
        end

        def write(endpoints)
          write_to_file(endpoints, @endpoint_cache)
        end

        def read
          read_from_file(@endpoint_cache)
        end

        private

        def write_to_file(data, path)
          File.write(path, data.to_yaml(stringify_names: true))
        end

        def read_from_file(path)
          YAML.safe_load_file(path, symbolize_names: true, permitted_classes: [Symbol, Time])
        end

        def specs_updated?
          return true if !File.exist?(@spec_cache)

          cache = read_from_file(@spec_cache)
          new_cache = generate_spec_cache

          different?(cache, new_cache)
        end

        def endpoint_cache?
          File.exist?(@endpoint_cache)
        end

        def generate_spec_cache
          paths = SpecForge.forge_path.join("specs", "**", "*.{yml,yaml}")

          Dir[paths].each_with_object({}) do |path, hash|
            hash[path.to_sym] = File.mtime(path)
          end
        end

        def write_spec_cache
          data = generate_spec_cache
          write_to_file(data, @spec_cache)
        end

        def different?(cache_left, cache_right)
          # The number of files changed
          return true if cache_left.size != cache_right.size

          default_time = Time.now

          # Check if any of the files have changed since last time
          cache_left.any? do |path, time_left|
            time_right = cache_right[path] || default_time

            time_left != time_right
          end
        end
      end
    end
  end
end
