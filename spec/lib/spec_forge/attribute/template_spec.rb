# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Template do
  let(:input) { "" }

  subject(:attribute) { described_class.new(input) }

  context "when the input is just the template" do
    let(:input) { "{{ user_id_1 }}" }

    it "works" do
      puts attribute.inspect
      puts "VALUE: #{attribute.value}"
      puts "RESOLVED: #{attribute.resolved}"
      binding.pry
    end
  end
end
