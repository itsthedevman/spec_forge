# frozen_string_literal: true

RSpec.describe SpecForge::Matchers do
  describe "forge_and" do
    context "when there is one successful check" do
      it "is expected to pass" do
        expect("hello").to forge_and(be_kind_of(String))
      end
    end

    context "when there are two successful checks" do
      it "is expected to pass all checks" do
        expect("hello").to forge_and(
          be_kind_of(String),
          match(/ell/)
        )
      end
    end

    context "when there are three successful checks" do
      it "is expected to pass all checks" do
        expect("hello world").to forge_and(
          be_kind_of(String),
          match(/ell/),
          end_with("rld")
        )
      end
    end

    context "when there is one failed check" do
      it do
        expect {
          expect("hello").to forge_and(be_kind_of(Integer))
        }.to raise_error(RSpec::Expectations::ExpectationNotMetError) do |e|
          expect(e.message).to include("Expected to satisfy ALL of these conditions on:")
          expect(e.message).to include("hello".in_quotes)
          expect(e.message).to include("❌ 1. be a kind of Integer")
          expect(e.message).to include("expected \"hello\" to be a kind of Integer")
          expect(e.message).to include("0/1 conditions met")
        end
      end
    end

    context "when there are two failed checks" do
      it do
        expect {
          expect(true).to forge_and(
            be_kind_of(Integer),
            start_with("o")
          )
        }.to raise_error(RSpec::Expectations::ExpectationNotMetError) do |e|
          expect(e.message).to include("Expected to satisfy ALL of these conditions on:")
          expect(e.message).to include("true")
          expect(e.message).to include("❌ 1. be a kind of Integer")
          expect(e.message).to include("expected true to be a kind of Integer")
          expect(e.message).to include("❌ 2. start with \"o\"")
          expect(e.message).to include("expected true to start with \"o\"")
          expect(e.message).to include("0/2 conditions met")
        end
      end
    end

    context "when there are three failed checks" do
      it do
        expect {
          expect(1).to forge_and(
            end_with("a"),
            be_kind_of(String),
            eq(5)
          )
        }.to raise_error(RSpec::Expectations::ExpectationNotMetError) do |e|
          expect(e.message).to include("Expected to satisfy ALL of these conditions on:")
          expect(e.message).to include("1")
          expect(e.message).to include("❌ 1. end with \"a\"")
          expect(e.message).to include("expected 1 to end with \"a\"")
          expect(e.message).to include("❌ 2. be a kind of String")
          expect(e.message).to include("expected 1 to be a kind of String")
          expect(e.message).to include("❌ 3. eq 5")
          expect(e.message).to include("expected: 5 got: 1")
          expect(e.message).to include("0/3 conditions met")
        end
      end
    end

    context "when there is one successful and one failure check" do
      it do
        expect {
          expect([]).to forge_and(
            be_kind_of(Array),
            be_present
          )
        }.to raise_error(RSpec::Expectations::ExpectationNotMetError) do |e|
          expect(e.message).to include("Expected to satisfy ALL of these conditions on:")
          expect(e.message).to include("[]")
          expect(e.message).to include("✅ 1. be a kind of Array")
          expect(e.message).to include("❌ 2. be present")
          expect(e.message).to include("expected `[].present?` to be truthy, got false")
          expect(e.message).to include("1/2 conditions met")
        end
      end
    end
  end

  describe "have_size" do
    context "when the object responds to #size" do
      context "and it is the same size" do
        it "passes" do
          expect([5]).to have_size(1)
        end
      end

      context "and it has different sizes" do
        it do
          expect {
            expect([5]).to have_size(0)
          }.to raise_error(RSpec::Expectations::ExpectationNotMetError) do |e|
            expect(e.message).to include("expected [5] size to eq 0, but got 1")
          end
        end
      end
    end

    context "when the object does not respond to #size" do
      it do
        expect {
          expect(nil).to have_size(1)
        }.to raise_error(RSpec::Expectations::ExpectationNotMetError) do |e|
          expect(e.message).to include("expected nil to respond to :size")
        end
      end
    end
  end
end
