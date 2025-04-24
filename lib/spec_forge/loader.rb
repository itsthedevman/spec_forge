# frozen_string_literal: true

module SpecForge
  #
  # Responsible for loading specs from YAML files and converting them to testable objects
  #
  # The Loader reads spec files, parses them as YAML, and transforms them into
  # a structure that can be used to create Forge objects. It also extracts
  # metadata like line numbers for error reporting.
  #
  # @example Loading all specs
  #   specs = Loader.load_from_files
  #
  class Loader
    class << self
      #
      # Loads all spec YAML files and transforms them into normalized structures
      #
      # @return [Array<Array>] Array of [global, metadata, specs] for each loaded file
      #
      def load_from_files
        # metadata is not normalized because its not user managed
        load_specs_from_files.map do |global, metadata, specs|
          global =
            begin
              Normalizer.normalize_global_context!(global)
            rescue => e
              raise Error::SpecLoadError.new(e, metadata[:relative_path])
            end

          specs =
            specs.map do |spec|
              Normalizer.normalize_spec!(spec, label: "spec \"#{spec[:name]}\"")
            rescue => e
              raise Error::SpecLoadError.new(e, metadata[:relative_path], spec:)
            end

          [global, metadata, specs]
        end
      end

      #
      # Internal method that handles loading specs from files
      #
      # This method coordinates the entire spec loading process by:
      # 1. Reading files from the specs directory
      # 2. Parsing them as YAML
      # 3. Transforming them into the proper structure
      #
      # @return [Array<Array>] Array of [global, metadata, specs] for each loaded file
      #
      # @private
      #
      def load_specs_from_files
        files = read_from_files
        parse_and_transform_specs(files)
      end

      #
      # Reads spec files from the spec_forge/specs directory
      #
      # @return [Array<Array<String, String>>] Array of [file_path, file_content] pairs
      #
      # @private
      #
      def read_from_files
        path = SpecForge.forge_path.join("specs")

        Dir[path.join("**/*.yml")].map do |file_path|
          [file_path, File.read(file_path)]
        end
      end

      #
      # Parses YAML content and extracts line numbers for error reporting
      #
      # @param files [Array<Array<String, String>>] Array of [file_path, file_content] pairs
      #
      # @return [Array<Array>] Array of [global, metadata, specs] for each file
      #
      # @private
      #
      def parse_and_transform_specs(files)
        base_path = SpecForge.forge_path.join("specs")

        files.map do |file_path, content|
          relative_path = Pathname.new(file_path).relative_path_from(base_path)

          hash = YAML.load(content, symbolize_names: true)

          file_line_numbers = extract_line_numbers(content, hash)

          # Currently, only holds onto global variables
          global = hash.delete(:global) || {}

          metadata = {
            file_name: relative_path.basename(".yml").to_s,
            relative_path: relative_path.to_s,
            file_path:
          }

          specs =
            hash.map do |spec_name, spec_hash|
              line_number, *expectation_line_numbers = file_line_numbers[spec_name]

              spec_hash[:id] = "spec_#{generate_id(spec_hash)}"
              spec_hash[:name] = spec_name.to_s
              spec_hash[:file_path] = metadata[:file_path]
              spec_hash[:file_name] = metadata[:file_name]
              spec_hash[:line_number] = line_number

              # Check for expectations instead of defaulting. I want it to error
              if (expectations = spec_hash[:expectations])
                expectations.zip(expectation_line_numbers) do |expectation_hash, line_number|
                  expectation_hash[:id] = "expect_#{generate_id(expectation_hash)}"
                  expectation_hash[:name] = build_expectation_name(spec_hash, expectation_hash)
                  expectation_hash[:line_number] = line_number
                end
              end

              spec_hash
            end

          [global, metadata, specs]
        end
      end

      #
      # Extracts line numbers from each YAML section for error reporting
      #
      # @param content [String] The raw file content
      # @param input_hash [Hash] The parsed YAML structure
      #
      # @return [Hash] A mapping of spec names to line numbers
      #
      # @private
      #
      def extract_line_numbers(content, input_hash)
        # I hate this code, lol, and it hates me.
        # I've tried to make it better, I've tried to clean it up, but every time I break it.
        # If you know how to make this better, please submit a PR and save me.
        spec_names = input_hash.keys
        keys = {}

        current_spec_name = nil
        expectations_line = nil
        expectations_indent = nil

        content.lines.each_with_index do |line, index|
          line_number = index + 1
          clean_line = line.rstrip
          indentation = line[/^\s*/].size

          # Skip blank lines
          next if clean_line.empty?

          # Reset on top-level elements
          if indentation == 0
            current_spec_name = nil
            expectations_line = nil
            expectations_indent = nil

            # Check if this line starts a spec we're interested in
            spec_names.each do |spec_name|
              next unless clean_line.start_with?("#{spec_name}:")

              current_spec_name = spec_name
              keys[current_spec_name] = [line_number]
              break
            end

            next
          end

          # Skip if we're not in a relevant spec
          next unless current_spec_name

          # Found expectations section
          if clean_line.match?(/^[^#]\s*expectations:/i)
            expectations_line = line_number
            expectations_indent = indentation
            next
          end

          # Found an expectation item
          if expectations_line && clean_line.start_with?("#{" " * expectations_indent}- ")
            keys[current_spec_name] << line_number
          end
        end

        keys
      end

      #
      # Generates a unique ID for an object based on hash and object_id
      #
      # @param object [Object] The object to generate an ID for
      #
      # @return [String] A unique ID string
      #
      # @private
      #
      def generate_id(object)
        "#{object.hash.abs.to_s(36)}_#{object.object_id.to_s(36)}"
      end

      #
      # Builds a name for an expectation based on HTTP verb, URL, and optional name
      #
      # @param spec_hash [Hash] The spec configuration
      # @param expectation_hash [Hash] The expectation configuration
      #
      # @return [String] A formatted expectation name (e.g., "GET /users - Find User")
      #
      # @private
      #
      def build_expectation_name(spec_hash, expectation_hash)
        # Create a structure for these two attributes
        # Removing the defaults and validators to avoid issues
        structure = Normalizer::SHARED_ATTRIBUTES.slice(:http_verb, :url)
          .transform_values { |v| v.except(:default, :validator) }

        # Ignore any errors. It'll be caught above anyway
        normalized_spec, _errors = Normalizer.new("", spec_hash, structure:).normalize
        normalized_expectation, _errors = Normalizer.new("", expectation_hash, structure:).normalize

        request_data = normalized_spec.deep_merge(normalized_expectation)

        url = request_data[:url]
        http_verb = request_data[:http_verb].presence || "GET"

        # Finally generate the name
        generate_expectation_name(http_verb:, url:, name: expectation_hash[:name])
      end

      #
      # Generates an expectation name from its components
      #
      # @param http_verb [String] The HTTP verb (GET, POST, etc.)
      # @param url [String] The URL path
      # @param name [String, nil] Optional descriptive name
      #
      # @return [String] A formatted expectation name
      #
      # @private
      #
      def generate_expectation_name(http_verb:, url:, name: nil)
        base = "#{http_verb.upcase} #{url}"   # GET /users
        base += " - #{name}" if name.present? # GET /users - Returns 404 because y not?
        base
      end
    end
  end
end
