# frozen_string_literal: true

# This is more for organizational purposes
RSpec.describe SpecForge::Normalizer do
  # This also tests normalize_expectation and normalize_constraint
  describe "normalize using spec" do
    let(:expectation) do
      {
        id: SecureRandom.uuid,
        name: Faker::String.random,
        line_number: 5,
        url: Faker::String.random,
        http_verb: SpecForge::HTTP::Verb::VERBS.keys.sample.to_s,
        headers: {
          some_header: Faker::String.random
        },
        query: {
          query_1: Faker::String.random,
          query_2: Faker::String.random
        },
        body: {
          body_1: Faker::String.random,
          body_2: Faker::String.random
        },
        variables: {
          variable_1: Faker::String.random,
          variable_2: Faker::String.random
        },
        expect: {
          status: 0,
          headers: {
            response_header: Faker::String.random
          },
          json: {
            json_1: Faker::String.random,
            json_2: Faker::String.random
          }
        }
      }
    end

    let(:spec) do
      {
        id: SecureRandom.uuid,
        name: Faker::String.random,
        file_name: "",
        file_path: "",
        line_number: 1,
        url: Faker::String.random,
        http_verb: SpecForge::HTTP::Verb::VERBS.keys.sample.to_s,
        headers: {
          some_header: Faker::String.random
        },
        query: {
          query_1: Faker::String.random,
          query_2: Faker::String.random
        },
        body: {
          body_1: Faker::String.random,
          body_2: Faker::String.random
        },
        variables: {
          variable_1: Faker::String.random,
          variable_2: Faker::String.random
        },
        expectations: [expectation]
      }
    end

    let(:normalized_expectation) { normalized[:expectations].first }
    let(:constraint) { expectation[:expect] }
    let(:normalized_constraint) { normalized[:expectations].first[:expect] }

    subject(:normalized) { described_class.normalize!(spec, using: :spec) }

    it "is expected to normalize fully" do
      expect(normalized[:url]).to be_kind_of(String)
      expect(normalized[:http_verb]).to be_kind_of(String)
      expect(normalized[:headers]).to be_kind_of(Hash)
      expect(normalized[:headers][:some_header]).to be_kind_of(String)
      expect(normalized[:query]).to be_kind_of(Hash)
      expect(normalized[:query][:query_1]).to be_kind_of(String)
      expect(normalized[:query][:query_2]).to be_kind_of(String)
      expect(normalized[:body]).to be_kind_of(Hash)
      expect(normalized[:body][:body_1]).to be_kind_of(String)
      expect(normalized[:body][:body_2]).to be_kind_of(String)
      expect(normalized[:variables]).to be_kind_of(Hash)
      expect(normalized[:variables][:variable_1]).to be_kind_of(String)
      expect(normalized[:variables][:variable_2]).to be_kind_of(String)
      expect(normalized[:expectations]).to be_kind_of(Array)

      expectation = normalized[:expectations].first
      expect(expectation[:name]).to be_kind_of(String)
      expect(expectation[:url]).to be_kind_of(String)
      expect(expectation[:http_verb]).to be_kind_of(String)
      expect(expectation[:headers]).to be_kind_of(Hash)
      expect(expectation[:headers][:some_header]).to be_kind_of(String)
      expect(expectation[:query]).to be_kind_of(Hash)
      expect(expectation[:query][:query_1]).to be_kind_of(String)
      expect(expectation[:query][:query_2]).to be_kind_of(String)
      expect(expectation[:body]).to be_kind_of(Hash)
      expect(expectation[:body][:body_1]).to be_kind_of(String)
      expect(expectation[:body][:body_2]).to be_kind_of(String)
      expect(expectation[:variables]).to be_kind_of(Hash)
      expect(expectation[:variables][:variable_1]).to be_kind_of(String)
      expect(expectation[:variables][:variable_2]).to be_kind_of(String)
      expect(expectation[:expect]).to be_kind_of(Hash)

      constraint = expectation[:expect]
      expect(constraint[:status]).to be_kind_of(Integer)
      expect(constraint[:json]).to be_kind_of(Hash)
      expect(constraint[:json][:json_1]).to be_kind_of(String)
      expect(constraint[:json][:json_2]).to be_kind_of(String)
    end

    context "when aliases are used" do
      before do
        spec[:path] = spec.delete(:url)
        spec[:method] = spec.delete(:http_verb)
        spec[:params] = spec.delete(:query)
        spec[:data] = spec.delete(:body)

        expectation[:path] = expectation.delete(:url)
        expectation[:method] = expectation.delete(:http_verb)
        expectation[:params] = expectation.delete(:query)
        expectation[:data] = expectation.delete(:body)
      end

      it "normalizes them" do
        expect(normalized).to include(
          url: spec[:path],
          http_verb: spec[:method],
          query: spec[:params],
          body: spec[:data],
          variables: spec[:variables],
          expectations: [
            include(
              url: expectation[:path],
              http_verb: expectation[:method],
              query: expectation[:params],
              body: expectation[:data]
            )
          ]
        )
      end
    end

    include_examples(
      "normalizer_defaults_value",
      {
        context: "when 'headers' is nil",
        before: -> { spec[:headers] = nil },
        input: -> { normalized[:headers] },
        default: {}
      },
      {
        context: "when 'query' is nil",
        before: -> { spec[:query] = nil },
        input: -> { normalized[:query] },
        default: {}
      },
      {
        context: "when 'body' is nil",
        before: -> { spec[:body] = nil },
        input: -> { normalized[:body] },
        default: {}
      },
      {
        context: "when 'variables' is nil",
        before: -> { spec[:variables] = nil },
        input: -> { normalized[:variables] },
        default: {}
      },
      {
        context: "when 'headers' is not a String",
        before: -> { expectation[:headers] = nil },
        input: -> { normalized_expectation[:headers] },
        default: {}
      },
      {
        context: "when 'query' is not a Hash",
        before: -> { expectation[:query] = nil },
        input: -> { normalized_expectation[:query] },
        default: {}
      },
      {
        context: "when 'body' is not a Hash",
        before: -> { expectation[:body] = nil },
        input: -> { normalized_expectation[:body] },
        default: {}
      },
      {
        context: "when 'variables' is not a Hash",
        before: -> { expectation[:variables] = nil },
        input: -> { normalized_expectation[:variables] },
        default: {}
      },
      {
        context: "when 'store_as' is nil",
        before: -> { expectation[:store_as] = nil },
        input: -> { normalized_expectation[:store_as] },
        default: ""
      },
      {
        context: "when 'status' is a String",
        before: -> { constraint[:status] = "global.variables.status" },
        input: -> { normalized_constraint[:status] },
        default: "global.variables.status"
      },
      {
        context: "when 'json' is not a Hash",
        before: -> { constraint[:json] = nil },
        input: -> { normalized_constraint[:json] },
        default: {}
      },
      {
        context: "when 'json' is an Array",
        before: -> { constraint[:json] = [] },
        input: -> { normalized_constraint[:json] },
        default: []
      }
    )

    include_examples(
      "normalizer_raises_invalid_structure",
      {
        context: "when 'base_url' is not a String",
        before: -> { spec[:base_url] = 1 },
        error: "Expected String, got Integer for \"base_url\" in spec (line 1)"
      },
      {
        context: "when 'url' is not a String",
        before: -> { spec[:url] = 1 },
        error: "Expected String, got Integer for \"url\" (aliases \"path\") in spec (line 1)"
      },
      {
        context: "when 'http_verb' is not a String",
        before: -> { spec[:http_verb] = 1 },
        error: "Expected String, got Integer for \"http_verb\" (aliases \"method\", \"http_method\") in spec (line 1)"
      },
      {
        context: "when 'headers' is not a Hash",
        before: -> { spec[:headers] = 1 },
        error: "Expected Hash, got Integer for \"headers\" in spec (line 1)"
      },
      {
        context: "when 'query' is not a Hash",
        before: -> { spec[:query] = 1 },
        error: "Expected Hash or String, got Integer for \"query\" (aliases \"params\") in spec (line 1)"
      },
      {
        context: "when 'body' is not a Hash",
        before: -> { spec[:body] = 1 },
        error: "Expected Hash or String, got Integer for \"body\" (aliases \"data\") in spec (line 1)"
      },
      {
        context: "when 'variables' is not a Hash",
        before: -> { spec[:variables] = 1 },
        error: "Expected Hash or String, got Integer for \"variables\" in spec (line 1)"
      },
      {
        context: "when 'expectations' is nil",
        before: -> { spec[:expectations] = nil },
        error: "Expected Array, got NilClass for \"expectations\" in spec (line 1)"
      },
      {
        context: "when 'expectations' is not an Array",
        before: -> { spec[:expectations] = 1 },
        error: "Expected Array, got Integer for \"expectations\" in spec (line 1)"
      },
      {
        context: "when 'url' is not a String",
        before: -> { expectation[:url] = 1 },
        error: "Expected String, got Integer for \"url\" (aliases \"path\") in index 0 of \"expectations\" in spec (line 5)"
      },
      {
        context: "when 'http_verb' is not a String",
        before: -> { expectation[:http_verb] = 1 },
        error: "Expected String, got Integer for \"http_verb\" (aliases \"method\", \"http_method\") in index 0 of \"expectations\" in spec (line 5)"
      },
      {
        context: "when 'http_verb' is not a valid verb",
        before: -> { expectation[:http_verb] = "TEG" },
        error: "Invalid HTTP verb \"TEG\" for \"http_verb\" (aliases \"method\", \"http_method\") in index 0 of \"expectations\" in spec. Valid values are: \"DELETE\", \"GET\", \"PATCH\", \"POST\", \"PUT\""
      },
      {
        context: "when 'expect' is not a Hash",
        before: -> { expectation[:expect] = nil },
        error: "Expected Hash, got NilClass for \"expect\" in index 0 of \"expectations\" in spec (line 5)"
      },
      {
        context: "when 'store_as' is not a String",
        before: -> { expectation[:store_as] = 1 },
        error: "Expected String, got Integer for \"store_as\" in index 0 of \"expectations\" in spec (line 5)"
      },
      {
        context: "when 'status' is not an Integer",
        before: -> { constraint[:status] = nil },
        error: "Expected Integer or String, got NilClass for \"status\" in expect (item 0)"
      }
    )
  end
end
