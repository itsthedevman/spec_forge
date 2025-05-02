# frozen_string_literal: true

module Generator
  class << self
    def empty_request_hash
      {base_url: "", url: "", http_verb: "", headers: {}, query: {}, body: {}}
    end

    def empty_expectation_hash
      structure = SpecForge::Normalizer.structures
        # One word: WEEEEEEEE!
        # Not joking, just how the data is set up
        .dig(:spec, :structure, :expectations, :structure, :structure)

      SpecForge::Normalizer.default(structure:, include_optional: true)
        .except(:variables, *empty_request_hash.keys)
    end

    def forge(global: {}, metadata: {}, specs: [])
      specs = specs.map do |spec|
        default_spec = SpecForge::Normalizer.default(:spec, include_optional: true)
        spec = default_spec.deep_merge(spec)

        spec[:id] = SecureRandom.uuid if spec[:id].blank?

        spec[:expectations].map! do |expectation|
          expectation = empty_expectation_hash.merge(expectation)

          expectation[:id] = SecureRandom.uuid if expectation[:id].blank?
          expectation[:expect][:status] = 404 if expectation[:expect][:status].blank?

          expectation
        end

        spec
      end

      SpecForge::Forge.new(global, metadata, specs)
    end
  end
end
