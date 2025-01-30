# frozen_string_literal: true

RSpec.describe SpecForge::HTTPMethod do
  let(:verb) {}

  subject(:method) { described_class.from(verb) }

  describe ".from" do
    context "when 'delete' is given" do
      let(:verb) { :delete }

      it { is_expected.to be_kind_of(described_class::Delete) }
    end

    context "when 'get' is given" do
      let(:verb) { :get }

      it { is_expected.to be_kind_of(described_class::Get) }
    end

    context "when 'patch' is given" do
      let(:verb) { :patch }

      it { is_expected.to be_kind_of(described_class::Patch) }
    end

    context "when 'post' is given" do
      let(:verb) { :post }

      it { is_expected.to be_kind_of(described_class::Post) }
    end

    context "when 'put' is given" do
      let(:verb) { :put }

      it { is_expected.to be_kind_of(described_class::Put) }
    end
  end

  describe "Predicates" do
    describe "delete?" do
      context "when the verb is the same" do
        let(:verb) { :delete }

        it { expect(method.delete?).to be(true) }
      end

      context "when the verb is not the same" do
        let(:verb) { :get }

        it { expect(method.delete?).to be(false) }
      end
    end

    describe "get?" do
      context "when the verb is the same" do
        let(:verb) { :get }

        it { expect(method.get?).to be(true) }
      end

      context "when the verb is not the same" do
        let(:verb) { :delete }

        it { expect(method.get?).to be(false) }
      end
    end

    describe "patch?" do
      context "when the verb is the same" do
        let(:verb) { :patch }

        it { expect(method.patch?).to be(true) }
      end

      context "when the verb is not the same" do
        let(:verb) { :get }

        it { expect(method.patch?).to be(false) }
      end
    end

    describe "post?" do
      context "when the verb is the same" do
        let(:verb) { :post }

        it { expect(method.post?).to be(true) }
      end

      context "when the verb is not the same" do
        let(:verb) { :get }

        it { expect(method.post?).to be(false) }
      end
    end

    describe "put?" do
      context "when the verb is the same" do
        let(:verb) { :put }

        it { expect(method.put?).to be(true) }
      end

      context "when the verb is not the same" do
        let(:verb) { :get }

        it { expect(method.put?).to be(false) }
      end
    end
  end
end
