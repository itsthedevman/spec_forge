# frozen_string_literal: true

RSpec.describe SpecForge::HTTP do
  describe ".status_code_to_description" do
    let(:code) {}

    subject(:description) { described_class.status_code_to_description(code) }

    context "when the status code is known" do
      let(:code) { 421 }

      it "is expected to return the description" do
        is_expected.to eq("421 Misdirected Request")
      end
    end

    context "when the status code is not known" do
      context "when informational (1xx)" do
        let(:code) { 150 }

        it { is_expected.to eq("150 Informational") }
      end

      context "when success (2xx)" do
        let(:code) { 299 }

        it { is_expected.to eq("299 Success") }
      end

      context "when redirection (3xx)" do
        let(:code) { 399 }

        it { is_expected.to eq("399 Redirection") }
      end

      context "when client error (4xx)" do
        let(:code) { 420 }

        it { is_expected.to eq("420 Client Error") }
      end

      context "when server error (5xx)" do
        let(:code) { 599 }

        it { is_expected.to eq("599 Server Error") }
      end

      context "when outside known ranges" do
        let(:code) { 600 }

        it { is_expected.to eq("600") }
      end
    end

    context "when given a string" do
      let(:code) { "404" }

      it { is_expected.to eq("404 Not Found") }
    end
  end
end
