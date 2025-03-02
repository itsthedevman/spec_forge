# frozen_string_literal: true

module SpecForge
  class Loader
    class << self
      def load_from_files
        load_specs_from_files.map do |relative_path, global, specs|
          global =
            begin
              Normalizer.normalize_global_context!(global)
            rescue => e
              raise SpecLoadError.new(e, relative_path)
            end

          specs =
            specs.map do |spec|
              Normalizer.normalize_spec!(spec, label: "spec \"#{spec[:name]}\"")
            rescue => e
              raise SpecLoadError.new(e, relative_path)
            end

          [global, specs]
        end
      end

      # @private
      def load_specs_from_files
        files = read_from_files
        parse_and_transform_specs(files)
      end

      # @private
      def read_from_files
        path = SpecForge.forge_path.join("specs")

        Dir[path.join("**/*.yml")].map do |file_path|
          [file_path, File.read(file_path)]
        end
      end

      # @private
      def parse_and_transform_specs(files)
        base_path = SpecForge.forge_path.join("specs")

        files.map do |file_path, content|
          relative_path = Pathname.new(file_path).relative_path_from(base_path)

          hash = YAML.load(content).deep_symbolize_keys

          file_line_numbers = extract_line_numbers(content, hash)

          # Currently, only holds onto global variables
          global = hash.delete(:global) || {}

          specs =
            hash.map do |spec_name, spec_hash|
              line_number, *expectation_line_numbers = file_line_numbers[spec_name]

              spec_hash[:name] = spec_name.to_s
              spec_hash[:file_path] = file_path
              spec_hash[:file_name] = relative_path.basename(".yml").to_s

              # Store the lines numbers for both the spec and each expectation
              spec_hash[:line_number] = line_number

              # Check for expectations instead of defaulting. I want it to error
              if (expectations = spec_hash[:expectations])
                expectations.zip(expectation_line_numbers) do |expectation, line_number|
                  expectation[:line_number] = line_number
                end
              end

              spec_hash
            end

          [relative_path, global, specs]
        end
      end

      # @private
      def extract_line_numbers(content, input_hash)
        spec_names = input_hash.keys
        keys = {}

        current_spec_name = nil
        in_expectations = false

        content.lines.each_with_index do |line, index|
          line_number = index + 1
          indentation = line[/^\s*/].size

          # If we hit a line with no indentation, it's a new top-level element
          if indentation == 0
            current_spec_name = nil
            in_expectations = false

            # Check if this line starts a spec we're interested in
            spec_names.each do |spec_name|
              next unless line.start_with?("#{spec_name}:")

              current_spec_name = spec_name
              keys[current_spec_name] = [line_number]
              break
            end

            next
          end

          # Skip if we're not in a relevant spec
          next unless current_spec_name

          # Check for expectations section
          if !in_expectations && line.match?(/^\s+expectations:/i)
            in_expectations = true
            next
          end

          # Record expectation lines
          if in_expectations && line.match?(/^\s+-/)
            keys[current_spec_name] << line_number
          end
        end

        keys
      end
    end
  end
end
