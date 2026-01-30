# frozen_string_literal: true

RSpec.describe Array do
  describe "#to_merged_h" do
    it "merges an array of hashes into a single hash" do
      result = [{a: 1}, {b: 2}].to_merged_h
      expect(result).to eq({a: 1, b: 2})
    end

    it "deep merges overlapping keys" do
      result = [{a: {x: 1}}, {a: {y: 2}}].to_merged_h
      expect(result).to eq({a: {x: 1, y: 2}})
    end

    it "overwrites scalar values with later values" do
      result = [{a: 1}, {a: 3}].to_merged_h
      expect(result).to eq({a: 3})
    end

    it "returns an empty hash for an empty array" do
      result = [].to_merged_h
      expect(result).to eq({})
    end

    it "handles a single hash" do
      result = [{a: 1, b: 2}].to_merged_h
      expect(result).to eq({a: 1, b: 2})
    end
  end
end
