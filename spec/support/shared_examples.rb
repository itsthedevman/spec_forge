# frozen_string_literal: true

RSpec.shared_examples("from_input_to_attribute") do
  context "when it is resolved via .from" do
    subject(:attribute) { SpecForge::Attribute.from(input) }

    it "is expected to convert to an instance of #{described_class}" do
      is_expected.to be_kind_of(described_class)
    end
  end
end

RSpec.shared_examples("raises_invalid_structure_error") do
  let(:error_message) { "" }
  let(:error_messages) { [] }
  let(:expect_block) { -> {} }

  before do
    error_messages << error_message if error_message.present?
  end

  it do
    expect { instance_exec(&expect_block) }.to(
      raise_error(SpecForge::Error::InvalidStructureError) do |e|
        error_messages.each do |message|
          expect(e.message).to include(message)
        end
      end
    )
  end
end

# include_examples(
#   "normalizer_raises_invalid_structure",
#   {
#     context: xxx,
#     before: -> xxx,
#     error: xxx
#   },
# )
RSpec.shared_examples("normalizer_raises_invalid_structure") do |*checks|
  checks.each do |check|
    context(check[:context] || "") do
      before do
        block = check[:before] || -> {}
        instance_exec(&block)
      end

      include_examples("raises_invalid_structure_error") do
        let(:expect_block) { -> { normalized } }
        let(:error_message) { check[:error] }
        let(:error_messages) { check[:errors] || [] }
      end
    end
  end
end

# include_examples(
#   "normalizer_defaults_value",
#   {
#     context: xxx,
#     before: -> xxx,
#     input: -> { xxx },
#     default: xxx
#   },
# )
RSpec.shared_examples("normalizer_defaults_value") do |*checks|
  checks.each do |check|
    context(check[:context] || "") do
      before do
        block = check[:before] || -> {}
        instance_exec(&block)
      end

      it "is expected to default its value" do
        result = instance_exec(&check[:input])

        default = check[:default]
        default = instance_exec(&block) if default.is_a?(Proc)

        expect(result).to eq(default)
      end
    end
  end
end
