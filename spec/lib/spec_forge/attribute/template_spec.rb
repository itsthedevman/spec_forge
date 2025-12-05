# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Template do
  let(:input) { "" }

  subject(:attribute) { described_class.new(input) }

  context "when the input is just the template" do
    let(:input) { "Hello user:{{ user_id_1 }}. You are the {{user_id_1}}th user!" }

    it "works" do
      context = SpecForge::Forge::Context.new(
        local_variables: {user_id_1: 99},
        global_variables: {}
      )

      SpecForge::Forge.with_context(context) do
        puts attribute.inspect
        puts "VALUE: #{attribute.value}"
        puts "RESOLVED: #{attribute.resolved}"
        binding.pry
      end
    end
  end
end
