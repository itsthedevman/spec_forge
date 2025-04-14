# frozen_string_literal: true

RSpec.describe SpecForge::Documentation::Renderers::File do
  subject(:file) { described_class.new }

  describe "#to_file" do
    let(:render_output) {}
    let(:file_output) {}
    let(:path) { Pathname.new("some/file/path/openapi.json") }

    subject(:to_file) { file.to_file(path) }

    before do
      expect(file).to receive(:render).and_return(render_output)
    end

    context "when the rendered output is a String" do
      let(:render_output) { "hello" }

      it "is expected to write to a file" do
        expect(File).to receive(:write).with(be_kind_of(Pathname), render_output)

        to_file
      end
    end

    context "when the path ends in .json" do
      let(:render_output) { {foo: 1} }

      it "is expected to write JSON to a file" do
        expect(File).to receive(:write)
          .with(be_kind_of(Pathname), JSON.pretty_generate(render_output))

        to_file
      end
    end

    context "when the path extension is .yml" do
      let(:path) { Pathname.new("openapi.yml") }

      let(:render_output) { {foo: 1} }

      it "is expected to write YAML to a file" do
        expect(File).to receive(:write)
          .with(be_kind_of(Pathname), render_output.to_yaml(stringify_names: true))

        to_file
      end
    end

    context "when the path extension is .yaml" do
      let(:path) { Pathname.new("openapi.yaml") }

      let(:render_output) { {foo: 1} }

      it "is expected to write YAML to a file" do
        expect(File).to receive(:write)
          .with(be_kind_of(Pathname), render_output.to_yaml(stringify_names: true))

        to_file
      end
    end
  end
end
