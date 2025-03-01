# frozen_string_literal: true

RSpec.describe SpecForge::Loader do
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
