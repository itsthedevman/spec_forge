# frozen_string_literal: true

module SpecForge
  module Documentation
    class Builder
      #
      # Manages caching of endpoint data to avoid re-running blueprints
      #
      # The Cache stores extracted endpoint data and tracks blueprint file
      # modification times. When blueprints haven't changed, cached data
      # can be reused to speed up documentation generation.
      #
      # Cache files are stored in the OpenAPI generated directory under
      # a .cache subdirectory.
      #
      # @example Using the cache
      #   cache = Cache.new
      #   if cache.valid?
      #     endpoints = cache.read
      #   else
      #     endpoints = extract_from_blueprints
      #     cache.create(endpoints)
      #   end
      #
      class Cache
        #
        # Creates a new cache manager
        #
        # Sets up file paths for endpoint and blueprint caches in the OpenAPI
        # generated directory structure.
        #
        # @return [Cache] A new cache instance
        #
        def initialize
          @endpoint_cache = SpecForge.openapi_path.join("generated", ".cache", "endpoints.yml")
          @blueprint_cache = SpecForge.openapi_path.join("generated", ".cache", "blueprints.yml")
        end

        #
        # Checks if the cache is valid and can be used
        #
        # Determines cache validity by checking if endpoint cache exists
        # and whether any blueprint files have been modified since the cache
        # was created.
        #
        # @return [Boolean] true if cache is valid and can be used
        #
        def valid?
          endpoint_cache? && !blueprints_updated?
        end

        #
        # Creates a cache entry with endpoint data and blueprint file metadata
        #
        # Writes both the endpoint data and current blueprint file modification times
        # to enable cache invalidation when blueprints change.
        #
        # @param endpoints [Array<Hash>] Endpoint data to cache
        #
        # @return [void]
        #
        def create(endpoints)
          write_blueprint_cache
          write(endpoints)
        end

        #
        # Writes endpoint data to the cache file
        #
        # @param endpoints [Array<Hash>] Endpoint data to write
        #
        # @return [void]
        #
        def write(endpoints)
          write_to_file(endpoints, @endpoint_cache)
        end

        #
        # Reads cached endpoint data from disk
        #
        # @return [Array<Hash>] Previously cached endpoint data
        #
        # @raise [StandardError] If cache file is missing or corrupted
        #
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

        def blueprints_updated?
          return true if !File.exist?(@blueprint_cache)

          cache = read_from_file(@blueprint_cache)
          new_cache = generate_blueprint_cache

          different?(cache, new_cache)
        end

        def endpoint_cache?
          File.exist?(@endpoint_cache)
        end

        def generate_blueprint_cache
          paths = SpecForge.forge_path.join("blueprints", "**", "*.{yml,yaml}")

          Dir[paths].each_with_object({}) do |path, hash|
            hash[path.to_sym] = File.mtime(path)
          end
        end

        def write_blueprint_cache
          data = generate_blueprint_cache
          write_to_file(data, @blueprint_cache)
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
