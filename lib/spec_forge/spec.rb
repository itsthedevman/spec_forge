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
        spec.run!
      rescue => e
        failures << [spec, e]
      end

      if failures.present?
        # TEMP
        raise StandardError, failures.join_map("\n") do |(spec, error)|
          <<~STRING.chomp
            #{error.message}
            #{error.backtrace}

            #{spec}
          STRING
        end
      end

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

          specs << new(**spec_hash)
        end
      end

      specs
    end

    ############################################################################

    attr_reader :name, :expectations

    delegate :url, :http_method, :content_type, :params, :body, to: :@request

    def initialize(**options)
      @name = options[:name]
      @request = Request.new(**options)
      @expectations = (options[:expectations] || []).map.with_index do |e, index|
        Expectation.new(e, "expectation #{index + 1}")
      end
    end

    def run!
      compile
      register_with_rspec
      run
    end

    def compile
      failures = []

      # Build the expectations, this can cause a failure
      @expectations.each_with_index do |expectation, index|
        expectation.compile(self)
      rescue => error
        failures << [expectation, index + 1, error]
      end
    end

    def register_with_rspec
      # Store the scope
      # Specific naming to avoid naming collisions
      spec_forge_context = self

      # And register with RSpec
      RSpec.describe(name) do
        spec_forge_context.expectations.each do |spec_forge_expectation|
          # Define the example group
          describe(spec_forge_expectation.name) do
            # Define any variables for this test
            spec_forge_expectation.variables.each do |variable_name, attribute|
              let(variable_name, &attribute.to_proc)
            end

            # Define the example
            example(&spec_forge_expectation.to_example_proc)
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
