# frozen_string_literal: true

module Generator
  class << self
    def empty_request_hash
      {base_url: "", url: "", http_verb: "", headers: {}, query: {}, body: {}}
    end

    def empty_expectation_hash
      SpecForge::Normalizer.default_expectation.except(:variables, *empty_request_hash.keys)
    end

    def forge(global: {}, metadata: {}, specs: [])
      specs = specs.map do |spec|
        default_spec = SpecForge::Normalizer.default_spec
        spec = default_spec.deep_merge(spec)

        spec[:id] = SecureRandom.uuid if spec[:id].blank?

        spec[:expectations].map! do |expectation|
          default_expectation = SpecForge::Normalizer.default_expectation
          expectation = default_expectation.deep_merge(expectation)

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
