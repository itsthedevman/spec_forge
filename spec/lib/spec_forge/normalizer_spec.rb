# frozen_string_literal: true

RSpec.describe SpecForge::Normalizer do
  describe ".normalize_spec!" do
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

    subject(:normalized) { described_class.normalize_spec!(spec) }

    it "is expected to normalize fully" do
      expect(normalized[:url]).to be_kind_of(String)
      expect(normalized[:http_method]).to be_kind_of(String)
      expect(normalized[:content_type]).to be_kind_of(String)
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
      expect(expectation[:http_method]).to be_kind_of(String)
      expect(expectation[:content_type]).to be_kind_of(String)
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
            "Expected String, got Integer for \"base_url\" on spec"
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
            "Expected String, got Integer for \"url\" on spec"
          )
        end
      end

      context "when 'http_method' is nil" do
        before do
          spec[:http_method] = nil
        end

        it "is expected to default to an empty string" do
          expect(normalized[:http_method]).to eq("")

          # Ensure the value is disconnected from the default
          default_value = described_class::Spec::STRUCTURE[:http_method][:default]
          expect(default_value).not_to eq(normalized[:http_method].object_id)
        end
      end

      context "when 'http_method' is not a String" do
        before do
          spec[:http_method] = 1
        end

        it do
          expect { normalized }.to raise_error(
            SpecForge::InvalidStructureError,
            "Expected String, got Integer for \"http_method\" on spec"
          )
        end
      end

      context "when 'content_type' is nil" do
        before do
          spec[:content_type] = nil
        end

        it "is expected to default to an empty string" do
          expect(normalized[:content_type]).to eq("")
        end
      end

      context "when 'content_type' is not a String" do
        before do
          spec[:content_type] = 1
        end

        it do
          expect { normalized }.to raise_error(
            SpecForge::InvalidStructureError,
            "Expected String, got Integer for \"content_type\" on spec"
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
            "Expected Hash, got Integer for \"query\" on spec"
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
            "Expected Hash, got Integer for \"body\" on spec"
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
            "Expected Hash, got Integer for \"variables\" on spec"
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
            "Expected Array, got NilClass for \"expectations\" on spec"
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
            "Expected Array, got Integer for \"expectations\" on spec"
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

        it "is expected to default to an empty string" do
          expect(normalized_expectation[:http_method]).to eq("")

          # Ensure the value is disconnected from the default
          default_value = described_class::Expectation::STRUCTURE[:http_method][:default]
          expect(default_value).not_to eq(normalized_expectation[:http_method].object_id)
        end
      end

      context "when 'content_type' is not a String" do
        before do
          expectation[:content_type] = nil
        end

        it "is expected to default to 'application/json'" do
          expect(normalized_expectation[:content_type]).to eq("")
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
        expect(normalized).to include(
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

  describe ".normalize_factory!" do
    let(:factory) do
      {
        model_class: "User",
        variables: {
          var_1: "faker.number.positive",
          var_2: "Variable 2"
        },
        attributes: {
          id: "variables.var_1",
          name: "faker.name.name"
        }
      }
    end

    subject(:normalized) { described_class.normalize_factory!(factory) }

    it "is expected to normalize fully" do
      expect(normalized[:model_class]).to eq("User")
      expect(normalized[:variables]).to match(
        var_1: "faker.number.positive",
        var_2: "Variable 2"
      )

      expect(normalized[:attributes]).to match(
        id: "variables.var_1",
        name: "faker.name.name"
      )
    end

    context "when aliases are used" do
      before do
        factory[:class] = factory.delete(:model_class)
      end

      it "is expected to normalize" do
        expect(normalized[:model_class]).to eq(factory[:class])
      end
    end

    context "when 'model_class' is nil" do
      before do
        factory[:model_class] = nil
      end

      it "is expected to default to an empty string" do
        expect(normalized[:model_class]).to eq("")
      end
    end

    context "when 'model_class' is not a String" do
      before do
        factory[:model_class] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected String, got Integer for \"model_class\" on factory"
        )
      end
    end

    context "when 'variables' is nil" do
      before do
        factory[:variables] = nil
      end

      it "is expected to default to an empty hash" do
        expect(normalized[:variables]).to eq({})
      end
    end

    context "when 'variables' is not a Hash" do
      before do
        factory[:variables] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected Hash, got Integer for \"variables\" on factory"
        )
      end
    end

    context "when 'attributes' is nil" do
      before do
        factory[:attributes] = nil
      end

      it "is expected to default to an empty hash" do
        expect(normalized[:attributes]).to eq({})
      end
    end

    context "when 'attributes' is not a Hash" do
      before do
        factory[:attributes] = 1
      end

      it do
        expect { normalized }.to raise_error(
          SpecForge::InvalidStructureError,
          "Expected Hash, got Integer for \"attributes\" on factory"
        )
      end
    end
  end
end
