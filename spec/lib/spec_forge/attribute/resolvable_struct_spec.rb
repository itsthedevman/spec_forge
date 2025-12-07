# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::ResolvableStruct do
  let(:object) {}

  subject(:resolvable) { described_class.new(object) }

  describe "#resolve" do
    context "when wrapping a regular Struct" do
      let(:object) do
        Struct.new(:name, :email).new(
          name: SpecForge::Attribute.from("faker.name.name"),
          email: SpecForge::Attribute.from("faker.internet.email")
        )
      end

      it { expect(resolvable).to respond_to(:resolve) }

      it "is expected to recursively resolve the struct and return a new Struct" do
        resolved = resolvable.resolved

        expect(resolved).to be_kind_of(Struct)
        expect(resolved.name).to be_kind_of(String)
        expect(resolved.email).to be_kind_of(String)
        expect(resolved.email).to include("@")
      end
    end

    context "when wrapping OpenStruct" do
      let(:object) do
        OpenStruct.new(
          id: SpecForge::Attribute.from("faker.number.positive"),
          active: SpecForge::Attribute.from(true)
        )
      end

      it "is expected to recursively resolve and return an OpenStruct" do
        resolved = resolvable.resolved

        expect(resolved).to be_kind_of(OpenStruct)
        expect(resolved.id).to be_kind_of(Numeric)
        expect(resolved.active).to be(true)
      end
    end

    context "when wrapping Data" do
      let(:object) do
        Data.define(:user_id, :token).new(
          user_id: SpecForge::Attribute.from(42),
          token: SpecForge::Attribute.from("faker.string.random")
        )
      end

      it "is expected to recursively resolve and return a Data instance" do
        resolved = resolvable.resolved

        expect(resolved).to be_kind_of(Data)
        expect(resolved.user_id).to eq(42)
        expect(resolved.token).to be_kind_of(String)
      end
    end

    context "when fields contain nested structures" do
      let(:object) do
        Struct.new(:user, :metadata).new(
          user: SpecForge::Attribute.from({
            name: "faker.name.name",
            posts: [
              "faker.lorem.sentence"
            ]
          }),
          metadata: SpecForge::Attribute.from(["tag1", "tag2"])
        )
      end

      it "is expected to deeply resolve nested attributes" do
        resolved = resolvable.resolved

        # Nested hashes become structs due to to_struct conversion
        expect(resolved.user).to be_kind_of(Struct)
        expect(resolved.user.name).to be_kind_of(String)
        expect(resolved.user.posts.first).to be_kind_of(String)
        expect(resolved.metadata).to eq(["tag1", "tag2"])
      end
    end
  end

  describe "#resolved vs #resolve" do
    let(:object) do
      Struct.new(:random_value).new(
        random_value: SpecForge::Attribute.from("faker.string.random")
      )
    end

    it "is expected to cache #resolved but not #resolve" do
      first_resolved = resolvable.resolved
      second_resolved = resolvable.resolved
      expect(first_resolved.random_value).to eq(second_resolved.random_value)

      first_resolve = resolvable.resolve
      second_resolve = resolvable.resolve
      expect(first_resolve.random_value).not_to eq(second_resolve.random_value)
    end
  end

  describe "#resolve_as_matcher" do
    context "when used in expectations" do
      let(:object) do
        OpenStruct.new(
          id: SpecForge::Attribute.from("kind_of.integer"),
          name: SpecForge::Attribute.from("kind_of.string"),
          tags: SpecForge::Attribute.from(["/\\w+/", "admin"])
        )
      end

      it "is expected to convert attributes to matchers" do
        matcher = resolvable.resolve_as_matcher

        expect(matcher).to be_kind_of(RSpec::Matchers::BuiltIn::Include)

        # Test it actually works as a matcher
        test_hash = {
          "id" => 123,
          "name" => "Test User",
          "tags" => ["important", "admin"]
        }

        expect(test_hash).to matcher
      end
    end
  end

  describe "#value" do
    let(:object) { Struct.new(:foo).new(foo: "bar") }

    it "is expected to return the underlying struct" do
      expect(resolvable.value).to eq(object)
    end
  end
end
