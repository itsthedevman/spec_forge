# frozen_string_literal: true

# This is more for organizational purposes
RSpec.describe SpecForge::Normalizer do
  # This also tests normalize_expectation and normalize_constraint
  describe ".normalize_spec!" do
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

    subject(:normalized) { described_class.normalize_spec!(spec) }

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

    context "Normalizing Spec" do
      context "when 'base_url' is nil" do
        before do
          spec[:base_url] = nil
        end

        it "is expected to default to an empty string" do
          expect(normalized[:base_url]).to eq("")
        end
      end

      context "when 'base_url' is not a String" do
        before do
          spec[:base_url] = 1
        end

        it do
          expect { normalized }.to raise_error(
            SpecForge::InvalidStructureError,
            "Expected String, got Integer for \"base_url\" in spec (line 1)"
          )
        end
      end

      context "when 'url' is nil" do
        before do
          spec[:url] = nil
        end

        it "is expected to default to an empty string" do
          expect(normalized[:url]).to eq("")
        end
      end

      context "when 'url' is not a String" do
        before do
          spec[:url] = 1
        end

        it do
          expect { normalized }.to raise_error(
            SpecForge::InvalidStructureError,
            "Expected String, got Integer for \"url\" (aliases \"path\") in spec (line 1)"
          )
        end
      end

      context "when 'http_verb' is nil" do
        before do
          spec[:http_verb] = nil
        end

        it "is expected to default to an empty string" do
          expect(normalized[:http_verb]).to eq("")
        end
      end

      context "when 'http_verb' is not a String" do
        before do
          spec[:http_verb] = 1
        end

        it do
          expect { normalized }.to raise_error(
            SpecForge::InvalidStructureError,
            "Expected String, got Integer for \"http_verb\" (aliases \"method\", \"http_method\") in spec (line 1)"
          )
        end
      end

      context "when 'headers' is nil" do
        before do
          spec[:headers] = nil
        end

        it "is expected to default to an empty hash" do
          expect(normalized[:headers]).to eq({})
        end
      end

      context "when 'headers' is not a Hash" do
        before do
          spec[:headers] = 1
        end

        it do
          expect { normalized }.to raise_error(
            SpecForge::InvalidStructureError,
            "Expected Hash, got Integer for \"headers\" in spec (line 1)"
          )
        end
      end

      context "when 'query' is nil" do
        before do
          spec[:query] = nil
        end

        it "is expected to default to an empty hash" do
          expect(normalized[:query]).to eq({})

          # Ensure the value is disconnected from the default
          default_value = described_class::Spec::STRUCTURE[:query][:default]
          expect(default_value).not_to eq(normalized[:query].object_id)
        end
      end

      context "when 'query' is not a Hash" do
        before do
          spec[:query] = 1
        end

        it do
          expect { normalized }.to raise_error(
            SpecForge::InvalidStructureError,
            "Expected Hash, got Integer for \"query\" (aliases \"params\") in spec (line 1)"
          )
        end
      end

      context "when 'body' is nil" do
        before do
          spec[:body] = nil
        end

        it "is expected to default to an empty hash" do
          expect(normalized[:body]).to eq({})
        end
      end

      context "when 'body' is not a Hash" do
        before do
          spec[:body] = 1
        end

        it do
          expect { normalized }.to raise_error(
            SpecForge::InvalidStructureError,
            "Expected Hash, got Integer for \"body\" (aliases \"data\") in spec (line 1)"
          )
        end
      end

      context "when 'variables' is nil" do
        before do
          spec[:variables] = nil
        end

        it "is expected to default to an empty hash" do
          expect(normalized[:variables]).to eq({})
        end
      end

      context "when 'variables' is not a Hash" do
        before do
          spec[:variables] = 1
        end

        it do
          expect { normalized }.to raise_error(
            SpecForge::InvalidStructureError,
            "Expected Hash, got Integer for \"variables\" in spec (line 1)"
          )
        end
      end

      context "when 'expectations' is nil" do
        before do
          spec[:expectations] = nil
        end

        it do
          expect { normalized }.to raise_error(
            SpecForge::InvalidStructureError,
            "Expected Array, got NilClass for \"expectations\" in spec (line 1)"
          )
        end
      end

      context "when 'expectations' is not an Array" do
        before do
          spec[:expectations] = 1
        end

        it do
          expect { normalized }.to raise_error(
            SpecForge::InvalidStructureError,
            "Expected Array, got Integer for \"expectations\" in spec (line 1)"
          )
        end
      end
    end

    context "Normalizing Expectations" do
      subject(:normalized_expectation) { normalized[:expectations].first }

      context "when a value is defaulted" do
        it "is expected to be a duplicated object" do
          default_value = described_class::Expectation::STRUCTURE[:http_verb][:default]
          expect(default_value).not_to eq(normalized_expectation[:http_verb].object_id)
        end
      end

      context "when 'url' is not a String" do
        before do
          expectation[:url] = nil
        end

        it "is expected to default to an empty string" do
          expect(normalized_expectation[:url]).to eq("")
        end
      end

      context "when 'http_verb' is nil" do
        before do
          expectation[:http_verb] = nil
        end

        it "is expected to default to an empty string" do
          expect(normalized_expectation[:http_verb]).to eq("")
        end
      end

      context "when 'http_verb' is not a String" do
        before do
          expectation[:http_verb] = 1
        end

        it do
          expect { normalized }.to raise_error(
            SpecForge::InvalidStructureError,
            "Expected String, got Integer for \"http_verb\" (aliases \"method\", \"http_method\") in expectation (item 0) (line 5)"
          )
        end
      end

      context "when 'http_verb' is not a valid verb" do
        before do
          expectation[:http_verb] = "TEG"
        end

        it do
          expect { normalized }.to raise_error(
            SpecForge::InvalidStructureError,
            "Invalid HTTP verb: TEG. Valid values are: DELETE, GET, PATCH, POST, PUT"
          )
        end
      end

      context "when 'headers' is not a String" do
        before do
          expectation[:headers] = nil
        end

        it do
          expect(normalized_expectation[:headers]).to eq({})
        end
      end

      context "when 'query' is not a Hash" do
        before do
          expectation[:query] = nil
        end

        it "is expected to default to an empty hash" do
          expect(normalized_expectation[:query]).to eq({})

          # Ensure the value is disconnected from the default
          default_value = described_class::Expectation::STRUCTURE[:query][:default]
          expect(default_value).not_to eq(normalized_expectation[:query].object_id)
        end
      end

      context "when 'body' is not a Hash" do
        before do
          expectation[:body] = nil
        end

        it "is expected to default to an empty hash" do
          expect(normalized_expectation[:body]).to eq({})
        end
      end

      context "when 'variables' is not a Hash" do
        before do
          expectation[:variables] = nil
        end

        it "is expected to default to an empty hash" do
          expect(normalized_expectation[:variables]).to eq({})
        end
      end

      context "when 'expect' is not a Hash" do
        before do
          expectation[:expect] = nil
        end

        it do
          expect { normalized }.to raise_error(
            SpecForge::InvalidStructureError,
            "Expected Hash, got NilClass for \"expect\" in expectation (item 0) (line 5)"
          )
        end
      end
    end

    context "Normalizing Constraints" do
      let(:constraint) { expectation[:expect] }

      subject(:normalized_constraint) { normalized[:expectations].first[:expect] }

      context "when 'status' is not an Integer" do
        before do
          constraint[:status] = nil
        end

        it do
          expect { normalized }.to raise_error(
            SpecForge::InvalidStructureError,
            "Expected Integer or String, got NilClass for \"status\" in expect (item 0)"
          )
        end
      end

      context "when 'status' is a String" do
        before do
          constraint[:status] = "global.variables.status"
        end

        it do
          expect(normalized_constraint[:status]).to eq("global.variables.status")
        end
      end

      context "when 'json' is not a Hash" do
        before do
          constraint[:json] = nil
        end

        it "is expected to default to an empty hash" do
          expect(normalized_constraint[:json]).to eq({})
        end
      end

      context "when 'json' is an Array" do
        before do
          constraint[:json] = []
        end

        it "is expected to allow it" do
          expect(normalized_constraint[:json]).to eq([])
        end
      end
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
              body: expectation[:data],
              variables: expectation[:variables],
              expect: expectation[:expect]
            )
          ]
        )
      end
    end
  end
end
