# frozen_string_literal: true

RSpec.describe SpecForge::Runner::Callbacks do
  let(:global) { {} }
  let(:metadata) { {} }
  let(:specs) { [] }

  let(:forge) { Generator.forge(global:, metadata:, specs:) }

  # These are not called directly by this file. They'll be called as part of the lifecycle
  let(:request) do
    SpecForge::HTTP::Request.new(
      base_url: "", url: "", http_verb: "GET", headers: {}, query: {}, body: {}
    )
  end

  let(:response) { Faraday::Response.new }

  subject(:callbacks) { described_class }

  describe "The callback lifecycle" do
    let(:global) do
      {
        variables: {
          var_1: "faker.number.positive",
          var_2: [2]
        }
      }
    end

    let(:specs) do
      [
        {
          file_path: "test/path",
          variables: {
            var_1: "faker.string.random",
            var_2: "global.variables.var_2"
          },
          expectations: [
            {store_as: "stored_as_file"},
            {store_as: "spec.stored_as_spec", variables: {var_1: "/hello/", var_2: 1}},
            {variables: {var_3: 3}}
          ]
        },
        {} # Empty spec, needed just to test it doing a reset
      ]
    end

    subject(:context) { SpecForge.context }

    before do
      ### Seed to ensure data is reset
      context.global.set(variables: {test: true})
      context.store.set(1, request: {}, variables: {}, response: {}, scope: :file)
      context.variables.set(base: {test: true}, overlay: {test: {var_1: true}})
    end

    it "is expected to fully complete the lifecycle" do
      ##########################################################################
      ## before_file
      callbacks.before_file(forge)

      # Global variables are resolved
      global_variables = context.global.variables

      expect(global_variables).not_to match(
        var_1: be_kind_of(SpecForge::Attribute),
        var_2: be_kind_of(SpecForge::Attribute)
      )

      expect(global_variables).to match(var_1: be_kind_of(Numeric), var_2: [2])

      # The store is reset
      expect(context.store.size).to eq(0)

      ##########################################################################
      ## before_spec, spec 0
      spec = forge.specs.first
      callbacks.before_spec(forge, spec)

      # Ensure the spec level variables are resolved correctly
      expect(context.variables).not_to match(
        var_1: be_kind_of(SpecForge::Attribute),
        var_2: be_kind_of(SpecForge::Attribute)
      )

      expect(context.variables).to match(var_1: be_kind_of(String), var_2: [2])
      expect(context.variables.overlay.size).to eq(2) # First expectation has no overlays

      ##########################################################################
      ## before_expectation, expectation 0
      expectation = spec.expectations.first
      callbacks.before_expectation(forge, spec, expectation, self, RSpec.current_example)

      # Check our test's metadata, since it modifies it lol
      expect(RSpec.current_example.metadata[:location]).to start_with("test/path")

      # No overlaid variables, still using the spec's
      variables = context.variables
      expect(variables).not_to match(
        var_1: be_kind_of(SpecForge::Attribute),
        var_2: be_kind_of(SpecForge::Attribute)
      )

      expect(variables).to match(var_1: be_kind_of(String), var_2: [2])

      ##########################################################################
      ## after_expectation, expectation 0

      # This is usually set by RSpec in a callback - so manually it is.
      # I love potentially hiding bugs! /s
      SpecForge::Runner::State.set(response:)

      # Pass in this example so it can access request and response variables
      callbacks.after_expectation(forge, spec, expectation, self, RSpec.current_example)

      # This expectation is stored at the file level
      expect(context.store.size).to eq(1)
      expect(context.store["stored_as_file"]).to have_attributes(
        scope: :file,
        request: include(:base_url, :url, :headers, :body, :http_verb, :query),
        variables: match(var_1: be_kind_of(String), var_2: [2]),
        response: be_kind_of(Faraday::Response),
        headers: be_kind_of(Hash),
        status: be(nil),
        body: be(nil)
      )

      ##########################################################################
      ## before_expectation, expectation 1
      expectation = spec.expectations.second
      callbacks.before_expectation(forge, spec, expectation, self, RSpec.current_example)

      # Now we have overlaid variables
      variables = context.variables
      expect(variables).not_to match(
        var_1: be_kind_of(SpecForge::Attribute),
        var_2: be_kind_of(SpecForge::Attribute)
      )

      expect(variables).to match(var_1: be_kind_of(Regexp), var_2: 1)

      ##########################################################################
      ## after_expectation, expectation 1

      # This is usually set by RSpec in a callback - so manually it is.
      # I love potentially hiding bugs! /s
      SpecForge::Runner::State.set(response:)

      # Pass in this example so it can access request and response variables
      callbacks.after_expectation(forge, spec, expectation, self, RSpec.current_example)

      # This expectation is stored at the spec level
      expect(context.store.size).to eq(2)
      expect(context.store["stored_as_spec"]).to have_attributes(
        scope: :spec,
        request: include(:base_url, :url, :headers, :body, :http_verb, :query),
        variables: match(var_1: be_kind_of(Regexp), var_2: 1),
        response: be_kind_of(Faraday::Response),
        headers: be_kind_of(Hash),
        status: be(nil),
        body: be(nil)
      )

      ##########################################################################
      ## before_expectation, expectation 2
      expectation = spec.expectations.third
      callbacks.before_expectation(forge, spec, expectation, self, RSpec.current_example)

      # Now we have a combination of variables
      variables = context.variables
      expect(variables).not_to match(
        var_1: be_kind_of(SpecForge::Attribute),
        var_2: be_kind_of(SpecForge::Attribute),
        var_3: be_kind_of(SpecForge::Attribute)
      )

      expect(variables).to match(
        var_1: be_kind_of(String),
        var_2: [2],
        var_3: 3
      )

      ##########################################################################
      ## after_expectation, expectation 2

      # This is usually set by RSpec in a callback - so manually it is.
      # I love potentially hiding bugs! /s
      SpecForge::Runner::State.set(response:)

      # Pass in this example so it can access request and response variables
      callbacks.after_expectation(forge, spec, expectation, self, RSpec.current_example)

      # This expectation is not stored
      expect(context.store.size).to eq(2)

      ##########################################################################
      ## before_spec, spec 1
      spec = forge.specs.second
      callbacks.before_spec(forge, spec)

      # Ensure it was reset and ready for the next spec
      expect(context.variables.base).to eq({})
      expect(context.variables.overlay.size).to eq(0)
      expect(context.store.size).to eq(1) # One expectation was stored at the file level

      # And we're done!
    end
  end

  # {before_spec: "cb_before_spec", after_spec: "cb_after_spec"},
  # {before_each: "cb_before_each", after_each: "cb_after_each"},
  # {around_each: "cb_around_each"}
  describe "The user defined callback lifecycle" do
    let(:specs) do
      [{
        name: "spec_name",
        variables: {var_1: true},
        expectations: [{}]
      }]
    end

    let(:metadata) do
      {
        file_path: "test/path/test.yml",
        file_name: "test"
      }
    end

    let(:results) { [] }
    let(:results_proc) { ->(c) { results << c } }

    context "when 'before_file'/'after_file' is called" do
      let(:global) do
        {
          callbacks: [
            {before_file: "cb_before_file", after_file: "cb_after_file"}
          ]
        }
      end

      let(:expected) do
        {
          callback_scope: "file",
          forge: be_kind_of(SpecForge::Forge),
          file_path: "test/path/test.yml",
          file_name: "test"
        }
      end

      before do
        SpecForge::Callbacks.register(:cb_before_file, &results_proc)
        SpecForge::Callbacks.register(:cb_after_file, &results_proc)
      end

      it "is expected to execute the callback with context data" do
        # before_file
        expected.merge!(callback_type: "before_file", callback_timing: "before")

        callbacks.before_file(forge)
        expect(results.first).to have_attributes(**expected)

        # after_file
        expected.merge!(callback_type: "after_file", callback_timing: "after")

        callbacks.after_file(forge)
        expect(results.second).to have_attributes(**expected)
      end
    end

    context "when 'before_spec'/'after_spec' is called" do
      let(:global) do
        {
          callbacks: [
            {before_spec: "cb_before_spec", after_spec: "cb_after_spec"}
          ]
        }
      end

      let(:expected) do
        {
          callback_scope: "spec",
          forge: be_kind_of(SpecForge::Forge),
          file_path: "test/path/test.yml",
          file_name: "test",
          spec: be_kind_of(SpecForge::Spec),
          spec_name: "spec_name",
          variables: have_attributes(var_1: true)
        }
      end

      before do
        SpecForge::Callbacks.register(:cb_before_spec, &results_proc)
        SpecForge::Callbacks.register(:cb_after_spec, &results_proc)

        # Needs to be called for the global context to be loaded
        callbacks.before_file(forge)
      end

      it "is expected to execute the callback with context data" do
        # before_spec
        expected.merge!(callback_type: "before_spec", callback_timing: "before")

        callbacks.before_spec(forge, forge.specs.first)
        expect(results.first).to have_attributes(**expected)

        # after_spec
        expected.merge!(callback_type: "after_spec", callback_timing: "after")

        callbacks.after_spec(forge, forge.specs.first)
        expect(results.second).to have_attributes(**expected)
      end
    end

    context "when 'before_each'/'after_each' is called" do
      let(:global) do
        {
          callbacks: [
            {before_each: "cb_before_each", after_each: "cb_after_each"}
          ]
        }
      end

      let(:expected) do
        {
          callback_scope: "each",
          forge: be_kind_of(SpecForge::Forge),
          file_path: "test/path/test.yml",
          file_name: "test",
          spec: be_kind_of(SpecForge::Spec),
          spec_name: "spec_name",
          variables: have_attributes(var_1: true),
          expectation: be_kind_of(SpecForge::Spec::Expectation),
          expectation_name: be_kind_of(String),
          request: be_kind_of(SpecForge::HTTP::Request),
          example_group: be_kind_of(RSpec::Core::ExampleGroup),
          example: be_kind_of(RSpec::Core::Example)
        }
      end

      before do
        SpecForge::Callbacks.register(:cb_before_each, &results_proc)
        SpecForge::Callbacks.register(:cb_after_each, &results_proc)

        # Needs to be called for the global context to be loaded
        callbacks.before_file(forge)
        callbacks.before_spec(forge, forge.specs.first)
      end

      it "is expected to execute the callback with context data" do
        spec = forge.specs.first

        args = [
          forge,
          spec,
          spec.expectations.first,
          self,
          RSpec.current_example
        ]

        # before_each
        expected.merge!(
          response: be(nil),
          callback_type: "before_each",
          callback_timing: "before"
        )

        callbacks.before_expectation(*args)
        expect(results.first).to have_attributes(**expected)

        # after_each
        expected.merge!(
          response: be_kind_of(Faraday::Response),
          callback_type: "after_each",
          callback_timing: "after"
        )

        # This is usually set by RSpec in a callback - so manually it is.
        # I love potentially hiding bugs! /s
        SpecForge::Runner::State.set(response:)

        callbacks.after_expectation(*args)
        expect(results.second).to have_attributes(**expected)
      end
    end
  end
end
