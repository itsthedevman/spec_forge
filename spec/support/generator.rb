# frozen_string_literal: true

module Generator
  class << self
    def empty_request_hash
      {base_url: "", url: "", http_verb: "", headers: {}, query: {}, body: {}}
    end

    def empty_expectation
      SpecForge::Normalizer.default_expectation.except(:variables, *empty_request_hash.keys)
    end
  end
end
