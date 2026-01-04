# frozen_string_literal: true

RSpec.describe SpecForge::HTTP::Backend do
  subject(:backend) { described_class.new }

  describe "#initialize" do
    it "creates a Faraday connection" do
      expect(backend.connection).to be_a(Faraday::Connection)
    end
  end

  describe "HTTP methods" do
    it "responds to #get" do
      expect(backend).to respond_to(:get)
    end

    it "responds to #post" do
      expect(backend).to respond_to(:post)
    end

    it "responds to #put" do
      expect(backend).to respond_to(:put)
    end

    it "responds to #patch" do
      expect(backend).to respond_to(:patch)
    end

    it "responds to #delete" do
      expect(backend).to respond_to(:delete)
    end
  end
end
