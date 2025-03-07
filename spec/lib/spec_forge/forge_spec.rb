# frozen_string_literal: true

RSpec.describe SpecForge::Forge do
  describe "#initialize" do
    let(:global) { {} }
    let(:metadata) { {} }

    let(:specs) do
      [
        {
          id: SecureRandom.uuid,
          name: "spec_1",
          file_name: "spec_1",
          file_path: "spec_1.yml",
          line_number: 1,
          base_url: "https://example.com",
          url: "/example",
          http_verb: "GET",
          headers: {
            header_1: true
          },
          query: {
            query_1: true
          },
          body: {
            body_1: true
          },
          variables: {
            var_1: true
          },
          debug: false,
          expectations: [
            {
              id: SecureRandom.uuid,
              name: "GET /example - expectation_1",
              line_number: 1,
              debug: false,
              expect: {status: 404, json: {}}
            }
          ]
        },
        {
          id: SecureRandom.uuid,
          name: "spec_2",
          file_name: "spec_2",
          file_path: "spec_2.yml",
          line_number: 1,
          base_url: "",
          url: "/example",
          http_verb: "",
          headers: {
            header_1: true
          },
          query: {
            query_1: true
          },
          body: {
            body_1: true
          },
          variables: {
            var_1: true
          },
          debug: false,
          expectations: [
            {
              id: SecureRandom.uuid,
              name: "POST /example1",
              line_number: 1,
              base_url: "https://example1.com",
              url: "/example1",
              http_verb: "POST",
              headers: {
                header_1: false,
                header_2: true
              },
              query: {
                query_1: false,
                query_2: true
              },
              body: {
                body_1: false,
                body_2: true
              },
              variables: {
                var_1: false,
                var_2: true
              },
              debug: true,
              expect: {status: 404, json: {}}
            },
            {
              id: SecureRandom.uuid,
              line_number: 1,
              name: "GET /example",
              base_url: "",
              url: "",
              http_verb: "",
              headers: {
                header_1: false
              },
              query: {},
              body: {},
              variables: {
                var_3: false
              },
              debug: false,
              expect: {status: 404, json: {}}
            }
          ]
        }
      ]
    end

    subject(:forge) { described_class.new(global, metadata, specs) }

    context "when variables are defined" do
      subject(:variables) { forge.variables }

      it "is expected to extract them out" do
        spec_ids = specs.key_map(:id)
        expectation_ids = specs.second[:expectations].key_map(:id)

        is_expected.to match(
          spec_ids.first => {base: {var_1: true}, overlay: {}},
          spec_ids.second => {
            base: {var_1: true},
            overlay: {
              expectation_ids.first => {var_1: false, var_2: true},
              expectation_ids.second => {var_3: false}
            }
          }
        )
      end
    end

    context "when request data is defined" do
      subject(:request) { forge.request }

      before do
        SpecForge.configuration.base_url = "http://localhost"
      end

      it "is expected to extract them out" do
        spec_ids = specs.key_map(:id)
        expectation_ids = specs.second[:expectations].key_map(:id)

        is_expected.to match(
          spec_ids.first => {
            base: {
              base_url: "https://example.com",
              url: "/example",
              http_verb: "GET",
              headers: {header_1: true},
              query: {query_1: true},
              body: {body_1: true}
            },
            overlay: {}
          },
          spec_ids.second => {
            base: {
              base_url: "http://localhost", # This uses the default
              url: "/example",
              http_verb: "GET", # This uses the default
              headers: {header_1: true},
              query: {query_1: true},
              body: {body_1: true}
            },
            overlay: {
              expectation_ids.first => {
                base_url: "https://example1.com",
                url: "/example1",
                http_verb: "POST",
                headers: {header_1: false, header_2: true},
                query: {query_1: false, query_2: true},
                body: {body_1: false, body_2: true}
              },
              expectation_ids.second => {
                headers: {header_1: false}
              }
            }
          }
        )
      end
    end

    context "when there is spec data" do
      let(:spec_1) { converted_specs.first }
      let(:spec_2) { converted_specs.second }

      subject(:converted_specs) { forge.specs }

      it "is expected to name the expectations and convert them to specs" do
        is_expected.to all(be_kind_of(SpecForge::Spec))
        expect(converted_specs.size).to eq(2)

        # Spec 1
        og_spec = specs.first
        expect(spec_1).to have_attributes(
          id: og_spec[:id],
          name: "spec_1",
          file_path: "spec_1.yml",
          file_name: "spec_1",
          debug: false,
          line_number: 1,
          expectations: be_kind_of(Array)
        )

        # Spec 1 expectations
        expectation = spec_1.expectations.first
        og_expectation = og_spec[:expectations].first
        expect(expectation).to be_kind_of(SpecForge::Spec::Expectation)
        expect(expectation).to have_attributes(
          id: og_expectation[:id],
          name: "GET /example - expectation_1",
          line_number: 1,
          debug: false,
          constraints: have_attributes(
            status: SpecForge::Attribute.from(404),
            json: SpecForge::Attribute.from(nil)
          )
        )

        # Spec 2
        og_spec = specs.second
        expect(spec_2).to have_attributes(
          id: og_spec[:id],
          name: "spec_2",
          file_path: "spec_2.yml",
          file_name: "spec_2",
          debug: false,
          line_number: 1,
          expectations: be_kind_of(Array)
        )

        # Spec 2 expectations
        og_expectation_ids = og_spec[:expectations].key_map(:id)
        expect(spec_2.expectations).to all(be_kind_of(SpecForge::Spec::Expectation))

        expect(spec_2.expectations.first).to have_attributes(
          id: og_expectation_ids.first,
          name: "POST /example1",
          line_number: 1,
          debug: true,
          constraints: have_attributes(
            status: SpecForge::Attribute.from(404),
            json: SpecForge::Attribute.from(nil)
          )
        )

        expect(spec_2.expectations.second).to have_attributes(
          id: og_expectation_ids.second,
          name: "GET /example",
          line_number: 1,
          debug: false,
          constraints: have_attributes(
            status: SpecForge::Attribute.from(404),
            json: SpecForge::Attribute.from(nil)
          )
        )
      end
    end
  end
end
