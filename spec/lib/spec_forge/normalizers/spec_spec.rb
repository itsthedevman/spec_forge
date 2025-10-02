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
        base_url: Faker::String.random,
        url: Faker::String.random,
        http_verb: SpecForge::HTTP::Verb::VERBS.keys.sample.to_s,
        documentation: true,
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

    let(:constraint) { expectation[:expect] }

    let(:spec) do
      {
        id: SecureRandom.uuid,
        name: Faker::String.random,
        file_name: "",
        file_path: "",
        line_number: 1,
        base_url: Faker::String.random,
        url: Faker::String.random,
        http_verb: SpecForge::HTTP::Verb::VERBS.keys.sample.to_s,
        documentation: true,
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
    let(:normalized_constraint) { normalized_expectation[:expect] }

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
      expect(normalized[:documentation]).to be(true)

      expect(normalized_expectation[:name]).to be_kind_of(String)
      expect(normalized_expectation[:url]).to be_kind_of(String)
      expect(normalized_expectation[:http_verb]).to be_kind_of(String)
      expect(normalized_expectation[:headers]).to be_kind_of(Hash)
      expect(normalized_expectation[:headers][:some_header]).to be_kind_of(String)
      expect(normalized_expectation[:query]).to be_kind_of(Hash)
      expect(normalized_expectation[:query][:query_1]).to be_kind_of(String)
      expect(normalized_expectation[:query][:query_2]).to be_kind_of(String)
      expect(normalized_expectation[:body]).to be_kind_of(Hash)
      expect(normalized_expectation[:body][:body_1]).to be_kind_of(String)
      expect(normalized_expectation[:body][:body_2]).to be_kind_of(String)
      expect(normalized_expectation[:variables]).to be_kind_of(Hash)
      expect(normalized_expectation[:variables][:variable_1]).to be_kind_of(String)
      expect(normalized_expectation[:variables][:variable_2]).to be_kind_of(String)
      expect(normalized_expectation[:expect]).to be_kind_of(Hash)
      expect(normalized_expectation[:documentation]).to be(true)

      expect(normalized_constraint[:status]).to be_kind_of(Integer)
      expect(normalized_constraint[:json]).to be_kind_of(Hash)
      expect(normalized_constraint[:json][:json_1]).to be_kind_of(String)
      expect(normalized_constraint[:json][:json_2]).to be_kind_of(String)
    end

    context "when aliases are used" do
      before do
        spec[:base_path] = spec.delete(:base_url)
        spec[:path] = spec.delete(:url)
        spec[:method] = spec.delete(:http_verb)
        spec[:params] = spec.delete(:query)
        spec[:data] = spec.delete(:body)

        expectation[:base_path] = expectation.delete(:base_url)
        expectation[:path] = expectation.delete(:url)
        expectation[:method] = expectation.delete(:http_verb)
        expectation[:params] = expectation.delete(:query)
        expectation[:data] = expectation.delete(:body)
      end

      it "normalizes them" do
        expect(normalized).to include(
          base_url: spec[:base_path],
          url: spec[:path],
          http_verb: spec[:method],
          query: spec[:params],
          body: spec[:data],
          variables: spec[:variables],
          expectations: [
            include(
              base_url: expectation[:base_path],
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
        context: "when 'headers' on spec is nil",
        before: -> { spec[:headers] = nil },
        input: -> { normalized[:headers] },
        default: {}
      },
      {
        context: "when 'query' on spec is nil",
        before: -> { spec[:query] = nil },
        input: -> { normalized[:query] },
        default: {}
      },
      {
        context: "when 'body' on spec is nil",
        before: -> { spec[:body] = nil },
        input: -> { normalized[:body] },
        default: {}
      },
      {
        context: "when 'variables' on spec is nil",
        before: -> { spec[:variables] = nil },
        input: -> { normalized[:variables] },
        default: {}
      },
      {
        context: "when 'documentation' on spec is nil",
        before: -> { spec[:documentation] = nil },
        input: -> { normalized[:documentation] },
        default: true
      },
      {
        context: "when 'headers' on expectation is not a String",
        before: -> { expectation[:headers] = nil },
        input: -> { normalized_expectation[:headers] },
        default: {}
      },
      {
        context: "when 'query' on expectation is not a Hash",
        before: -> { expectation[:query] = nil },
        input: -> { normalized_expectation[:query] },
        default: {}
      },
      {
        context: "when 'body' on expectation is not a Hash",
        before: -> { expectation[:body] = nil },
        input: -> { normalized_expectation[:body] },
        default: {}
      },
      {
        context: "when 'variables' on expectation is not a Hash",
        before: -> { expectation[:variables] = nil },
        input: -> { normalized_expectation[:variables] },
        default: {}
      },
      {
        context: "when 'store_as' on expectation is nil",
        before: -> { expectation[:store_as] = nil },
        input: -> { normalized_expectation[:store_as] },
        default: ""
      },
      {
        context: "when 'documentation' on expectation is nil",
        before: -> { expectation[:documentation] = nil },
        input: -> { normalized_expectation[:documentation] },
        default: true
      },
      {
        context: "when 'status' on constraint is a String",
        before: -> { constraint[:status] = "global.variables.status" },
        input: -> { normalized_constraint[:status] },
        default: "global.variables.status"
      },
      {
        context: "when 'json' on constraint is not a Hash",
        before: -> { constraint[:json] = nil },
        input: -> { normalized_constraint[:json] },
        default: {}
      },
      {
        context: "when 'json' on constraint is an Array",
        before: -> { constraint[:json] = [] },
        input: -> { normalized_constraint[:json] },
        default: []
      }
    )

    include_examples(
      "normalizer_raises_invalid_structure",
      {
        context: "when 'base_url' on spec is not a String",
        before: -> { spec[:base_url] = 1 },
        error:
          "Expected String, got Integer for \"base_url\" (aliases \"base_path\") in spec (line 1)"
      },
      {
        context: "when 'url' on spec is not a String",
        before: -> { spec[:url] = 1 },
        error: "Expected String, got Integer for \"url\" (aliases \"path\") in spec (line 1)"
      },
      {
        context: "when 'http_verb' on spec is not a String",
        before: -> { spec[:http_verb] = 1 },
        error: "Expected String, got Integer for \"http_verb\" (aliases \"method\", \"http_method\") in spec (line 1)"
      },
      {
        context: "when 'headers' on spec is not a Hash",
        before: -> { spec[:headers] = 1 },
        error: "Expected Hash, got Integer for \"headers\" in spec (line 1)"
      },
      {
        context: "when 'query' on spec is not a Hash",
        before: -> { spec[:query] = 1 },
        error: "Expected Hash or String, got Integer for \"query\" (aliases \"params\") in spec (line 1)"
      },
      {
        context: "when 'body' on spec is not a Hash",
        before: -> { spec[:body] = 1 },
        error: "Expected Hash or String, got Integer for \"body\" (aliases \"data\") in spec (line 1)"
      },
      {
        context: "when 'variables' on spec is not a Hash",
        before: -> { spec[:variables] = 1 },
        error: "Expected Hash or String, got Integer for \"variables\" in spec (line 1)"
      },
      {
        context: "when 'expectations' on spec is nil",
        before: -> { spec[:expectations] = nil },
        error: "Expected Array, got NilClass for \"expectations\" in spec (line 1)"
      },
      {
        context: "when 'expectations' on spec is not an Array",
        before: -> { spec[:expectations] = 1 },
        error: "Expected Array, got Integer for \"expectations\" in spec (line 1)"
      },
      {
        context: "when 'url' on expectation is not a String",
        before: -> { expectation[:url] = 1 },
        error: "Expected String, got Integer for \"url\" (aliases \"path\") in index 0 of \"expectations\" in spec (line 5)"
      },
      {
        context: "when 'http_verb' on expectation is not a String",
        before: -> { expectation[:http_verb] = 1 },
        error: "Expected String, got Integer for \"http_verb\" (aliases \"method\", \"http_method\") in index 0 of \"expectations\" in spec (line 5)"
      },
      {
        context: "when 'http_verb' on expectation is not a valid verb",
        before: -> { expectation[:http_verb] = "TEG" },
        error: "Invalid HTTP verb \"TEG\" for \"http_verb\" (aliases \"method\", \"http_method\") in index 0 of \"expectations\" in spec. Valid values are: \"DELETE\", \"GET\", \"PATCH\", \"POST\", \"PUT\""
      },
      {
        context: "when 'expect' on expectation is not a Hash",
        before: -> { expectation[:expect] = nil },
        error: "Expected Hash, got NilClass for \"expect\" in index 0 of \"expectations\" in spec (line 5)"
      },
      {
        context: "when 'store_as' on expectation is not a String",
        before: -> { expectation[:store_as] = 1 },
        error: "Expected String, got Integer for \"store_as\" in index 0 of \"expectations\" in spec (line 5)"
      },
      {
        context: "when 'status' on constraint is not an Integer",
        before: -> { constraint[:status] = nil },
        error: "Expected Integer or String, got NilClass for \"status\" in \"expect\" in index 0 of \"expectations\" in spec"
      }
    )
  end
end
