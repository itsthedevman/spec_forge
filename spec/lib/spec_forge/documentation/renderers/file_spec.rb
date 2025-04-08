# frozen_string_literal: true

RSpec.describe SpecForge::Documentation::Renderers::File do
  subject(:file) { described_class.new }

  describe "#to_file" do
    let(:render_output) {}
    let(:file_output) {}
    let(:path) { "some/file/path" }

    let(:file_write_expectation) do
      expect(File).to receive(:write).with(be_kind_of(String), be_kind_of(String))
    end

    subject(:to_file) { file.to_file(path) }

    before do
      expect(file).to receive(:render).and_return(render_output)
    end

    context "when the rendered output is a String" do
      let(:render_output) { {foo: 1}.to_yaml }

      it "is expected to write to a file" do
        file_write_expectation.and_return(render_output)

        to_file
      end
    end

    context "when the rendered output is not a String" do
      let(:render_output) { {foo: 1} }

      it "is expected to write to a file" do
        file_write_expectation.and_return(render_output.to_json)

        to_file
      end
    end
  end
end
