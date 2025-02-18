# frozen_string_literal: true

RSpec.describe SpecForge::Spec::Expectation do
  describe "#initialize" do
    let(:input) { {} }
    let(:global_options) { {} }

    subject(:expectation) do
      described_class.new(
        SpecForge::Normalizer.normalize_expectations([input]).flatten.first,
        global_options: SpecForge::Normalizer.normalize_spec(global_options).first
      )
    end

    context "when 'global_options' is provided" do
      let(:input) do
        {
          url: "/users/admin",
          http_method: "POST",
          headers: {
            header_1: 3
          },
          query: {
            query_2: 3
          },
          body: {
            body_1: 3
          },
          variables: {
            var_2: 3
          },
          expect: {
            status: 404
          }
        }
      end

      let(:global_options) do
        {
          url: "/users",
          http_method: "GET",
          headers: {
            header_1: 1,
            header_2: 2
          },
          query: {
            query_1: 1,
            query_2: 2
          },
          body: {
            body_1: 1,
            body_2: 2
          },
          variables: {
            var_1: 1,
            var_2: 2
          }
        }
      end

      it "is expected to been deeply overwritten by the input" do
        request = expectation.http_client.request

        expect(expectation.variables).to eq(var_1: 1, var_2: 3)

        expect(request.url).to eq(input[:url])
        expect(request.http_method).to eq(input[:http_method])
        expect(request.headers).to eq("Header-1" => 3, "Header-2" => 2) # Request modifies these
        expect(request.query).to eq(query_1: 1, query_2: 3)
        expect(request.body).to eq(body_1: 3, body_2: 2)
      end
    end

    context "when 'global_options' is provided and input has empty values" do
      let(:input) do
        default = SpecForge::Normalizer.default_expectation
        default[:url] = "/url"
        default[:headers] = {}
        default[:body] = {}
        default[:query] = {}
        default[:variables] = {var_1: "data"}
        default[:expect][:status] = 404
        default
      end

      let(:global_options) do
        default = SpecForge::Normalizer.default_expectation
        default[:body] = {body_1: "data"}
        default[:query] = {query_1: "data"}
        default[:headers] = {header_1: "data"}
        default
      end

      it "is expected to not overwrite with empty values" do
        request = expectation.http_client.request

        expect(expectation.variables).to eq(var_1: "data")

        expect(request.url).to eq(input[:url])
        expect(request.http_method).to eq("GET")
        expect(request.headers).to eq("Header-1" => "data")
        expect(request.query).to eq(query_1: "data")
        expect(request.body).to eq(body_1: "data")
      end
    end

    context "when input is a valid hash" do
      let(:input) { {expect: {status: 404}} }

      it "is expected to compile" do
        expect(expectation.constraints.status).to eq(404)
      end
    end

    context "when 'name' is provided" do
      let(:input) { {url: "/testing", expect: {status: 404}, name: Faker::String.random} }

      it "is expected to append the name" do
        expect(expectation.name).to eq("GET /testing - #{input[:name]}")
      end
    end

    context "when 'name' is not provided" do
      let(:input) { {url: "/testing", expect: {status: 404}} }

      it "is expected to have the same name" do
        expect(expectation.name).to eq("GET /testing")
      end
    end

    context "when 'variables' is provided" do
      let(:input) { {expect: {status: 404}, variables: {foo: "bar"}} }

      it "is expected to convert the variable attributes" do
        expect(expectation.variables[:foo]).to be_kind_of(SpecForge::Attribute::Literal)
      end
    end

    context "when 'json' is provided on 'constraints'" do
      let(:input) { {expect: {status: 404, json: {key_1: "faker.number.positive"}}} }

      it "is expected to convert into a constraint" do
        expect(expectation.constraints.status).to eq(404)
        expect(expectation.constraints.json).to be_kind_of(SpecForge::Attribute::ResolvableHash)
        expect(expectation.constraints.json[:key_1]).to be_kind_of(SpecForge::Attribute::Faker)
      end
    end

    context "when 'variables' reference themselves" do
      let(:input) do
        {
          expect: {status: 404},
          variables: {
            var_1: "test",
            var_2: "variables.var_1"
          }
        }
      end

      it "is expected to be able to resolve the value" do
        expect(expectation.variables[:var_2].resolve).to eq(input[:variables][:var_1])
      end
    end

    context "when 'variables' reference themselves out of order" do
      let(:input) do
        {
          expect: {status: 404},
          variables: {
            var_4: "variables.var_3",
            var_1: "variables.var_5",
            var_3: "variables.var_2",
            var_2: "variables.var_1",
            var_5: "test"
          }
        }
      end

      it "is expected to be able to resolve the value" do
        expect(expectation.variables[:var_4].resolve).to eq("test")
      end
    end
  end
end
