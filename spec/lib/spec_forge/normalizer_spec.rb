# frozen_string_literal: true

RSpec.describe SpecForge::Normalizer do
  describe "#normalized" do
    let(:expectation) do
      {
        url: Faker::String.random,
        http_method: SpecForge::HTTP::Verb::VERBS.keys.sample.to_s,
        content_type: Faker::String.random,
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
        url: Faker::String.random,
        http_method: Faker::String.random,
        content_type: Faker::String.random,
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

    subject(:normalized) { described_class.new(spec).normalize }

    it "is expected to resolve fully" do
      expect(normalized.resolve).to match(
        url: be_kind_of(String),
        http_method: be_kind_of(String),
        content_type: be_kind_of(String),
        query: {
          query_1: be_kind_of(String),
          query_2: be_kind_of(String)
        },
        body: {
          body_1: be_kind_of(String),
          body_2: be_kind_of(String)
        },
        variables: {
          variable_1: be_kind_of(String),
          variable_2: be_kind_of(String)
        },
        expectations: [
          include(
            url: be_kind_of(String),
            http_method: be_kind_of(String),
            content_type: be_kind_of(String),
            query: {
              query_1: be_kind_of(String),
              query_2: be_kind_of(String)
            },
            body: {
              body_1: be_kind_of(String),
              body_2: be_kind_of(String)
            },
            variables: {
              variable_1: be_kind_of(String),
              variable_2: be_kind_of(String)
            },
            expect: {
              status: be_kind_of(Integer),
              json: {
                json_1: be_kind_of(String),
                json_2: be_kind_of(String)
              }
            }
          )
        ]
      )
    end

    context "Normalizing Spec" do
      context "when 'url' is not a String" do
        before do
          spec[:url] = nil
        end

        it "is expected to default to an empty string" do
          expect(normalized[:url]).to eq("")
        end
      end

      context "when 'http_method' is not a String" do
        before do
          spec[:http_method] = nil
        end

        it "is expected to default to 'GET'" do
          expect(normalized[:http_method]).to eq("GET")

          # Ensure the value is disconnected from the default
          default_value = described_class::SPEC_STRUCTURE[:http_method][:default]
          expect(default_value).not_to eq(normalized[:http_method].object_id)
        end
      end

      context "when 'content_type' is not a String" do
        before do
          spec[:content_type] = nil
        end

        it "is expected to default to 'application/json'" do
          expect(normalized[:content_type]).to eq("application/json")
        end
      end

      context "when 'query' is not a Hash" do
        before do
          spec[:query] = nil
        end

        it "is expected to default to an empty hash" do
          expect(normalized[:query]).to eq({})

          # Ensure the value is disconnected from the default
          default_value = described_class::SPEC_STRUCTURE[:query][:default]
          expect(default_value).not_to eq(normalized[:query].object_id)
        end
      end

      context "when 'body' is not a Hash" do
        before do
          spec[:body] = nil
        end

        it "is expected to default to an empty hash" do
          expect(normalized[:body]).to eq({})
        end
      end

      context "when 'variables' is not a Hash" do
        before do
          spec[:variables] = nil
        end

        it "is expected to default to an empty hash" do
          expect(normalized[:variables]).to eq({})
        end
      end

      context "when 'expectations' is not an Array" do
        before do
          spec[:expectations] = nil
        end

        it do
          expect { normalized }.to raise_error(
            SpecForge::InvalidStructureError,
            "Expected Array, got NilClass for \"expectations\" on spec"
          )
        end
      end
    end

    context "Normalizing Expectations" do
      subject(:normalized_expectation) { normalized[:expectations].first }

      context "when 'url' is not a String" do
        before do
          expectation[:url] = nil
        end

        it "is expected to default to an empty string" do
          expect(normalized_expectation[:url]).to eq("")
        end
      end

      context "when 'http_method' is not a String" do
        before do
          expectation[:http_method] = nil
        end

        it "is expected to default to 'GET'" do
          expect(normalized_expectation[:http_method]).to eq("GET")

          # Ensure the value is disconnected from the default
          default_value = described_class::EXPECTATION_STRUCTURE[:http_method][:default]
          expect(default_value).not_to eq(normalized_expectation[:http_method].object_id)
        end
      end

      context "when 'content_type' is not a String" do
        before do
          expectation[:content_type] = nil
        end

        it "is expected to default to 'application/json'" do
          expect(normalized_expectation[:content_type]).to eq("application/json")
        end
      end

      context "when 'query' is not a Hash" do
        before do
          expectation[:query] = nil
        end

        it "is expected to default to an empty hash" do
          expect(normalized_expectation[:query]).to eq({})

          # Ensure the value is disconnected from the default
          default_value = described_class::EXPECTATION_STRUCTURE[:query][:default]
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
            "Expected Hash, got NilClass for \"expect\" on expectation (item 0)"
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
            "Expected Integer, got NilClass for \"status\" on expect (item 0)"
          )
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
    end

    context "when aliases are used" do
      before do
        spec[:path] = spec.delete(:url)
        spec[:method] = spec.delete(:http_method)
        spec[:type] = spec.delete(:content_type)
        spec[:params] = spec.delete(:query)
        spec[:data] = spec.delete(:body)

        expectation[:path] = expectation.delete(:url)
        expectation[:method] = expectation.delete(:http_method)
        expectation[:type] = expectation.delete(:content_type)
        expectation[:params] = expectation.delete(:query)
        expectation[:data] = expectation.delete(:body)
      end

      it "normalizes them" do
        expect(normalized.resolve).to include(
          url: spec[:path],
          http_method: spec[:method],
          content_type: spec[:type],
          query: spec[:params],
          body: spec[:data],
          variables: spec[:variables],
          expectations: [
            include(
              url: expectation[:path],
              http_method: expectation[:method],
              content_type: expectation[:type],
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
