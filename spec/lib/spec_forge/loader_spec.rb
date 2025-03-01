# frozen_string_literal: true

RSpec.describe SpecForge::Loader do
  describe ".parse_and_transform_specs" do
    let(:files) do
      [
        [
          "file_path_1",
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
          "file_path_2",
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

    subject(:transformed) { described_class.parse_and_transform_specs("", files) }

    context "when a global context is defined" do
      let(:file_1) { transformed.first }

      it "is expected to extract out the global config and specs" do
        global = file_1.first
        expect(global).to eq(variables: {var_1: true})

        specs = file_1.second
        expect(specs).to include(include({name: "spec_1", file_path: "file_path_1"}))
      end
    end

    context "when a global context is not defined" do
      let(:file_2) { transformed.second }

      it "is expected to default to an empty hash" do
        global = file_2.first
        expect(global).to eq({})

        specs = file_2.second
        expect(specs).to include(include({name: "spec_2", file_path: "file_path_2"}))
      end
    end
  end

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
