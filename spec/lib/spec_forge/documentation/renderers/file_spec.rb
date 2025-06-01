# frozen_string_literal: true

RSpec.describe SpecForge::Documentation::Renderers::File do
  subject(:file) { described_class.new }

  describe "#to_file" do
    let(:render_output) {}
    let(:file_output) {}
    let(:file_format) { "json" }
    let(:path) { Pathname.new("some/file/path/openapi.json") }

    subject(:to_file) { file.to_file(path, file_format:) }

    before do
      expect(file).to receive(:render).and_return(render_output)
    end

    context "when the file_format is 'json'" do
      let(:render_output) { {foo: 1} }

      it "is expected to write JSON to a file" do
        expect(File).to receive(:write)
          .with(be_kind_of(Pathname), JSON.pretty_generate(render_output))

        to_file
      end
    end

    context "when the file_format is 'yml'" do
      let(:file_format) { "yml" }

      let(:render_output) { {foo: 1} }

      it "is expected to write YAML to a file" do
        expect(File).to receive(:write)
          .with(be_kind_of(Pathname), render_output.to_yaml(stringify_names: true))

        to_file
      end
    end
  end
end
