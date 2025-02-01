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
      specs = load_from_path(base_path.join("specs", "**/*.yml"))

      failures = []

      specs.each do |spec|
        spec.register_and_run
      rescue => e
        failures << [spec, e]
      end

      handle_failures!(failures) if failures.present?

      specs
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
          spec_hash[:file_path] = file_path

          specs << new(**spec_hash)
        end
      end

      specs
    end

    def self.handle_failures!(failures)
      # TEMP
      # TODO: Improve significantly!
      cleaner = SpecForge.backtrace_cleaner
      errors = failures.join_map("\n") do |(spec, error)|
        backtrace = cleaner.clean(error.backtrace)

        <<~STRING

          ---
          SpecForge raised an exception:
          File: #{spec.file_path}
          Spec Name: #{spec.name}

            #{error}
            #{backtrace.join("\n  ")}
        STRING
      end

      raise StandardError, errors
    end

    ############################################################################

    attr_reader :name, :file_path, :expectations

    delegate :url, :http_method, :content_type, :params, :body, to: :@request

    def initialize(**options)
      @name = options[:name]
      @file_path = options[:file_path]
      @request = Request.new(**options)
      @expectations = (options[:expectations] || []).map.with_index do |e, index|
        Expectation.new(e, "expectation #{index + 1}")
      end
    end

    def register_and_run
      compile
      register_with_rspec
      run
    end

    def compile
      failures = []

      # Build the expectations, this can cause a failure
      expectations.each_with_index do |expectation, index|
        puts "Compiling expectation #{index}"
        expectation.compile(self)
      rescue => error
        failures << [expectation, error]
      end

      self.class.handle_failures!(failures) if failures.present?
    end

    def register_with_rspec
      # Store the scope
      # Specific naming to avoid naming collisions
      spec_forge_context = self

      # And register with RSpec
      RSpec.describe(name) do
        spec_forge_context.expectations.each do |expectation_forge|
          # Define the example group
          describe(expectation_forge.name) do
            # Define any variables for this test
            expectation_forge.variables.each do |variable_name, attribute|
              let(variable_name, &attribute.to_proc)
            end

            # Define the example
            example(&expectation_forge.to_example_proc)
          end
        end
      end
    end

    def run
      # stdout = StringIO.new
      # stderr = StringIO.new

      RSpec::Core::Runner.disable_autorun!
      status = RSpec::Core::Runner.run([], $stderr, $stdout).to_i

      puts "Status: #{status}"
      # puts "STDOUT: #{stdout.read}"
      # puts "STDERR: #{stderr.read}"
    end
  end
end
