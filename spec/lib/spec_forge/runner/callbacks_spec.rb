# frozen_string_literal: true

RSpec.describe SpecForge::Runner::Callbacks do
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

    let(:forge) { Generator.forge(global:, metadata: {}, specs:) }

    # These are not called directly by this file. They'll be called on this example
    # during the lifecycle
    let(:request) { {query: {}} }
    let(:response) { {headers: {}, status: {}, body: {}}.to_istruct }

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
      global_variables = context.global.variables.resolve

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
      expect(context.variables.resolve_base).not_to match(
        var_1: be_kind_of(SpecForge::Attribute),
        var_2: be_kind_of(SpecForge::Attribute)
      )

      expect(context.variables.resolve_base).to match(var_1: be_kind_of(String), var_2: [2])
      expect(context.variables.overlay.size).to eq(2) # First expectation has no overlays

      ##########################################################################
      ## before_expectation, expectation 0
      expectation = spec.expectations.first
      callbacks.before_expectation(forge, spec, expectation)

      # Check our test's metadata, since it modifies it lol
      expect(RSpec.current_example.metadata[:location]).to start_with("test/path")

      # No overlaid variables, still using the spec's
      variables = context.variables.resolve
      expect(variables).not_to match(
        var_1: be_kind_of(SpecForge::Attribute),
        var_2: be_kind_of(SpecForge::Attribute)
      )

      expect(variables).to match(var_1: be_kind_of(String), var_2: [2])

      ##########################################################################
      ## after_expectation, expectation 0

      # Pass in this example so it can access request and response variables
      callbacks.after_expectation(forge, spec, expectation, self)

      # This expectation is stored at the file level
      expect(context.store.size).to eq(1)
      expect(context.store["stored_as_file"]).to have_attributes(
        scope: :file,
        request:,
        variables: match(var_1: be_kind_of(String), var_2: [2]),
        response: response.to_h
      )

      ##########################################################################
      ## before_expectation, expectation 1
      expectation = spec.expectations.second
      callbacks.before_expectation(forge, spec, expectation)

      # Now we have overlaid variables
      variables = context.variables.resolve
      expect(variables).not_to match(
        var_1: be_kind_of(SpecForge::Attribute),
        var_2: be_kind_of(SpecForge::Attribute)
      )

      expect(variables).to match(var_1: be_kind_of(Regexp), var_2: 1)

      ##########################################################################
      ## after_expectation, expectation 1

      # Pass in this example so it can access request and response variables
      callbacks.after_expectation(forge, spec, expectation, self)

      # This expectation is stored at the spec level
      expect(context.store.size).to eq(2)
      expect(context.store["stored_as_spec"]).to have_attributes(
        scope: :spec,
        request:,
        variables: match(var_1: be_kind_of(Regexp), var_2: 1),
        response: response.to_h
      )

      ##########################################################################
      ## before_expectation, expectation 2
      expectation = spec.expectations.third
      callbacks.before_expectation(forge, spec, expectation)

      # Now we have a combination of variables
      variables = context.variables.resolve
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

      # Pass in this example so it can access request and response variables
      callbacks.after_expectation(forge, spec, expectation, self)

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
end
