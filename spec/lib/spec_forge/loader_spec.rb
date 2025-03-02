# frozen_string_literal: true

RSpec.describe SpecForge::Loader do
  let(:file_path_1) { SpecForge.forge_path.join("specs", "spec_1.yml") }
  let(:file_path_2) { SpecForge.forge_path.join("specs", "spec_2.yml") }

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
        spec = specs.first.second.first

        expect(global).to have_key(:variables)
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
        expect { specs }.to raise_error(SpecForge::SpecLoadError) do |e|
          expect(e.message).to include("Error loading spec file: spec_1.yml")
          expect(e.message).to include("Cause: Expected Hash, got Integer")
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
        expect { specs }.to raise_error(SpecForge::SpecLoadError) do |e|
          expect(e.message).to include("Error loading spec file: spec_2.yml")
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
        file_name = file_1.first
        expect(file_name).to eq(Pathname.new("spec_1.yml"))

        global = file_1.second
        expect(global).to eq(variables: {var_1: true})

        specs = file_1.third
        expect(specs).to include(include({name: "spec_1", file_path: file_path_1}))
      end
    end

    context "when a global context is not defined" do
      let(:file_2) { transformed.second }

      it "is expected to default to an empty hash" do
        file_name = file_2.first
        expect(file_name).to eq(Pathname.new("spec_2.yml"))

        global = file_2.second
        expect(global).to eq({})

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
          - name: ""
            expect:
              status: 303

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
          spec_2: [7, 12, 15],
          spec_3: [19, 27, 32]
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
end
