# frozen_string_literal: true

RSpec.describe SpecForge::Type do
  let(:object) {}

  describe ".hash?" do
    subject(:is_hash) { described_class.hash?(object) }

    context "when the object is a Hash" do
      let(:object) { {} }

      it { is_expected.to be(true) }
    end

    context "when the object is a ResolvableHash" do
      let(:object) { SpecForge::Attribute.from({}) }

      it { is_expected.to be(true) }
    end

    context "when the object is neither" do
      let(:object) { "neither" }

      it { is_expected.to be(false) }
    end
  end

  describe ".array?" do
    subject(:is_array) { described_class.array?(object) }

    context "when the object is a Array" do
      let(:object) { [] }

      it { is_expected.to be(true) }
    end

    context "when the object is a ResolvableArray" do
      let(:object) { SpecForge::Attribute.from([]) }

      it { is_expected.to be(true) }
    end

    context "when the object is neither" do
      let(:object) { "neither" }

      it { is_expected.to be(false) }
    end
  end
end

RSpec.describe HashLike do
  subject(:is_hash) do
    case object
    when HashLike
      true
    else
      false
    end
  end

  context "when the object is a Hash" do
    let(:object) { {} }

    it { is_expected.to be(true) }
  end

  context "when the object is a ResolvableHash" do
    let(:object) { SpecForge::Attribute.from({}) }

    it { is_expected.to be(true) }
  end

  context "when the object is neither" do
    let(:object) { "neither" }

    it { is_expected.to be(false) }
  end
end

RSpec.describe ArrayLike do
  subject(:is_array) do
    case object
    when ArrayLike
      true
    else
      false
    end
  end

  context "when the object is a Array" do
    let(:object) { [] }

    it { is_expected.to be(true) }
  end

  context "when the object is a ResolvableArray" do
    let(:object) { SpecForge::Attribute.from([]) }

    it { is_expected.to be(true) }
  end

  context "when the object is neither" do
    let(:object) { "neither" }

    it { is_expected.to be(false) }
  end
end
