# frozen_string_literal: true

RSpec.describe SpecForge::Step::Expect do
  describe "#description" do
    context "when a custom name is provided" do
      it "returns the custom name" do
        expect = described_class.new(
          name: "Create user successfully",
          status: 201
        )

        expect(expect.description).to eq("Create user successfully")
      end

      it "ignores other fields when name is present" do
        expect = described_class.new(
          name: "Custom description",
          status: 201,
          headers: {"Content-Type" => "application/json"},
          json: {structure: {id: :integer}}
        )

        expect(expect.description).to eq("Custom description")
      end
    end

    context "when no name is provided" do
      context "with only status" do
        it "shows HTTP description for literal status" do
          expect = described_class.new(status: 201)

          expect(expect.description).to eq("201 Created")
        end

        it "shows 'expected status' for matcher status" do
          expect = described_class.new(status: "{{ be.greater_than(200) }}")

          expect(expect.description).to eq("expected status")
        end
      end

      context "with headers" do
        it "shows header count" do
          expect = described_class.new(
            status: 200,
            headers: {
              "Content-Type" => "application/json",
              "X-Request-ID" => "/^[a-f0-9-]+$/"
            }
          )

          expect(expect.description).to eq("200 OK, headers (2)")
        end

        it "doesn't show headers when empty" do
          expect = described_class.new(
            status: 200,
            headers: {}
          )

          expect(expect.description).to eq("200 OK")
        end
      end

      context "with raw body" do
        it "shows 'raw' when present" do
          expect = described_class.new(
            status: 200,
            raw: "exact match"
          )

          expect(expect.description).to eq("200 OK, raw")
        end

        it "shows 'raw' even with matchers" do
          expect = described_class.new(
            status: 200,
            raw: "{{ matcher.start_with('Hello') }}"
          )

          expect(expect.description).to eq("200 OK, raw")
        end
      end

      context "with JSON checks" do
        it "shows size when present" do
          expect = described_class.new(
            status: 200,
            json: {size: 5}
          )

          expect(expect.description).to eq("200 OK, size")
        end

        it "shows structure type for hash" do
          expect = described_class.new(
            status: 200,
            json: {
              structure: {
                id: :integer,
                name: :string
              }
            }
          )

          expect(expect.description).to eq("200 OK, structure (hash)")
        end

        it "shows structure type for array" do
          expect = described_class.new(
            status: 200,
            json: {
              structure: [
                {id: :integer, name: :string}
              ]
            }
          )

          expect(expect.description).to eq("200 OK, structure (array)")
        end

        it "shows content when present" do
          expect = described_class.new(
            status: 200,
            json: {
              content: {id: 42}
            }
          )

          expect(expect.description).to eq("200 OK, content")
        end

        it "combines multiple JSON checks" do
          expect = described_class.new(
            status: 201,
            json: {
              size: 5,
              structure: {id: :integer},
              content: {id: "{{ kind_of.integer }}"}
            }
          )

          expect(expect.description).to eq("201 Created, size, structure (hash), content")
        end
      end

      context "with multiple check types combined" do
        it "shows all parts in order" do
          expect = described_class.new(
            status: 201,
            headers: {
              "Content-Type" => "application/json",
              "X-Request-ID" => "/^uuid$/"
            },
            json: {
              structure: [
                {id: :integer}
              ],
              content: [{id: 1}, {id: 2}]
            }
          )

          expect(expect.description).to eq("201 Created, headers (2), structure (array), content")
        end

        it "handles matcher status with other checks" do
          expect = described_class.new(
            status: "{{ be.greater_than(200) }}",
            headers: {"Content-Type" => "application/json"},
            raw: "some text"
          )

          expect(expect.description).to eq("expected status, headers (1), raw")
        end
      end

      context "edge cases" do
        it "handles empty expect gracefully" do
          expect = described_class.new

          expect(expect.description).to eq("")
        end

        it "handles nil json gracefully" do
          expect = described_class.new(
            status: 200,
            json: nil
          )

          expect(expect.description).to eq("200 OK")
        end
      end
    end
  end
end
