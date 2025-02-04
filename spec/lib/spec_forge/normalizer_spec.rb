# frozen_string_literal: true

RSpec.describe SpecForge::Normalizer do
  describe "#normalized" do
    let(:expectations) do
      [
        {
          url: Faker::String.random,
          method: SpecForge::HTTP::Verb::VERBS.keys.sample.to_s,
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
      ]
    end

    let(:spec) do
      {
        url: Faker::String.random,
        method: Faker::String.random,
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
        expectations:
      }
    end

    subject(:normalized) { described_class.new(spec).normalize }

    context "Normalizing Spec" do
      context "when 'url' is not a String" do
        before do
          spec[:url] = nil
        end

        it "is expected to default to an empty string" do
          expect(normalized[:url]).to eq("")
        end
      end

      context "when 'method' is not a String" do
        before do
          spec[:method] = nil
        end

        it "is expected to default to 'GET'" do
          expect(normalized[:method]).to eq("GET")

          # Ensure the value is disconnected from the default
          default_value = described_class::SPEC_STRUCTURE[:method][:default]
          expect(default_value).not_to eq(normalized[:method].object_id)
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
  end
end
