# frozen_string_literal: true

RSpec.describe SpecForge::Loader do
  let(:file_path_1) { SpecForge.forge_path.join("specs", "spec_1.yml").to_s }
  let(:file_path_2) { SpecForge.forge_path.join("specs", "spec_2.yml").to_s }

  describe ".load_from_files" do
    subject(:specs) { described_class.load_from_files }

    before do
      expect(described_class).to receive("read_from_files").and_return(files)
    end

    context "when everything is valid" do
      let(:files) do
        [
          [
            file_path_1,
            <<~YAML
              spec_1:
                path: ""
                expectations:
                - expect:
                    status: 202
            YAML
          ]
        ]
      end

      it "is expected to return the normalized specs" do
        global = specs.first.first
        metadata = specs.first.second
        spec = specs.first.third.first

        expect(global).to have_key(:variables)
        expect(metadata).to include(file_name: "spec_1", file_path: file_path_1)
        expect(spec).to include(query: {}, body: {}, debug: false)
      end
    end

    context "when the global context is not valid" do
      let(:files) do
        [
          [
            file_path_1,
            <<~YAML
              global:
                variables: 1

              spec_1:
                path: ""
                expectations:
                - expect:
                    status: 202
            YAML
          ]
        ]
      end

      it do
        expect { specs }.to raise_error(SpecForge::Error::SpecLoadError) do |e|
          expect(e.message).to include("Error loading spec file \"spec_1.yml\"")
          expect(e.message).to include("Cause: Expected Hash or String, got Integer")
        end
      end
    end

    context "when a spec is not valid" do
      let(:files) do
        [
          [
            file_path_2,
            <<~YAML
              spec_1:
                path: 1
            YAML
          ]
        ]
      end

      it do
        expect { specs }.to raise_error(SpecForge::Error::SpecLoadError) do |e|
          expect(e.message).to include(
            "Error loading spec \"spec_1\" in file \"spec_2.yml\" (line 1)"
          )
          expect(e.message).to include("Causes:")
          expect(e.message).to include(
            %{Expected String, got Integer for "url" (aliases "path") in spec "spec_1" (line 1)}
          )
          expect(e.message).to include(
            %{Expected Array, got NilClass for "expectations" in spec "spec_1" (line 1)}
          )
        end
      end
    end
  end

  ##############################################################################

  describe ".parse_and_transform_specs" do
    let(:files) do
      [
        [
          file_path_1,
          <<~YAML
            global:
              variables:
                var_1: true

            spec_1:
              path: ""
              expectations:
              - expect:
                  status: 202
          YAML
        ],
        [
          file_path_2,
          <<~YAML
            spec_2:
              path: ""
              expectations:
              - expect:
                  status: 202
          YAML
        ]
      ]
    end

    subject(:transformed) { described_class.parse_and_transform_specs(files) }

    context "when a global context is defined" do
      let(:file_1) { transformed.first }

      it "is expected to extract out the global config and specs" do
        global = file_1.first
        expect(global).to eq(variables: {var_1: true})

        metadata = file_1.second
        expect(metadata).to include(file_name: "spec_1", file_path: file_path_1)

        specs = file_1.third
        expect(specs).to include(include({name: "spec_1", file_path: file_path_1}))
      end
    end

    context "when a global context is not defined" do
      let(:file_2) { transformed.second }

      it "is expected to default to an empty hash" do
        global = file_2.first
        expect(global).to eq({})

        metadata = file_2.second
        expect(metadata).to include(file_name: "spec_2", file_path: file_path_2)

        specs = file_2.third
        expect(specs).to include(include({name: "spec_2", file_path: file_path_2}))
      end
    end
  end

  ##############################################################################

  describe ".extract_line_numbers" do
    let(:content) do
      <<~YAML
        spec_1:
          path: ""
          expectations:
          - expect:
              status: 202

        spec_2:
          path: ""
          variables:
            var_1: ""
          expectations:
          - name: ""
            expect:
              status: 303
              json:
              - "foo"
          - name: ""
            expect:
              status: 303
              json:
                nested:
                  array:
                  - "This is to make sure it doesn't match to these"

        spec_3:
          path: ""
          body:
            body_1: ""
          query:
            query_1: ""
          expectations:
          # Maybe there's a comment?
          - variables:
              var_1: ""
            expect:
              status: 404
          # Oh yes, comments are nice
          - expect:
              status: 404
      YAML
    end

    let(:hash) { YAML.load(content).deep_symbolize_keys }

    subject(:line_numbers) { described_class.extract_line_numbers(content, hash) }

    context "when the file contains specs and expectations" do
      it "is expected to parse the line numbers for specs and expectations" do
        expect(line_numbers).to eq(
          spec_1: [1, 4],
          spec_2: [7, 12, 17],
          spec_3: [25, 33, 38]
        )
      end
    end

    context "when the file contains specs but one doesn't contain expectations" do
      let(:content) do
        <<~YAML
          spec_1:
            expectations:
            - expect:

          spec_2:

          spec_3:
            expectations:
            - expect:
        YAML
      end

      it "is expected to gracefully handle it" do
        expect(line_numbers).to eq(
          spec_1: [1, 3],
          spec_2: [5],
          spec_3: [7, 9]
        )
      end
    end

    context "when the file is just, wow. It's valid though!" do
      let(:content) do
        <<~YAML
          spec_1:
            expectations:
            - expect:
          spec_2:
          spec_3:
          spec_4:
          - foo
          - bar
        YAML
      end

      it "is expected to gracefully handle it" do
        expect(line_numbers).to eq(
          spec_1: [1, 3],
          spec_2: [4],
          spec_3: [5],
          spec_4: [6]
        )
      end
    end
  end

  describe ".build_expectation_name" do
    let(:spec) do
      {
        url: "/some_url",
        method: "PATCH"
      }
    end

    let(:expectation) { {} }

    subject(:name) { described_class.build_expectation_name(spec, expectation) }

    context "when the expectation has a name defined" do
      let(:expectation) do
        {name: Faker::String.random}
      end

      it "is expected to return a name from the spec's url, verb, and expectation's name" do
        is_expected.to eq("PATCH /some_url - #{expectation[:name]}")
      end
    end

    context "when the expectation has a verb defined" do
      let(:expectation) do
        {http_verb: "DELETE"}
      end

      it "is expected to return a name from the expectations's verb, and the spec's url" do
        is_expected.to eq("DELETE /some_url")
      end
    end

    context "when the expectation has a url defined" do
      let(:expectation) do
        {path: "/url_some"}
      end

      it "is expected to return a name from the expectations's url, and the spec's verb" do
        is_expected.to eq("PATCH /url_some")
      end
    end

    context "when the expectation has a url and verb defined" do
      let(:expectation) do
        {path: "/url_some", http_verb: "GET"}
      end

      it "is expected to return a name from the expectations's url, and verb" do
        is_expected.to eq("GET /url_some")
      end
    end

    context "when the expectation does not have a name, url, or verb" do
      it "is expected to return a name from the spec's data" do
        is_expected.to eq("PATCH /some_url")
      end
    end
  end
end
