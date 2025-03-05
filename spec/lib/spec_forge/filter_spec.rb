# frozen_string_literal: true

RSpec.describe SpecForge::Filter do
  describe ".apply" do
    let(:forges) do
      forges = [
        [
          {}, # Global
          {}, # Metadata
          [
            {
              id: SecureRandom.uuid,
              name: "spec_1",
              file_path: "",
              file_name: "specs",
              line_number: 0,
              url: "/specs",
              expectations: [
                {
                  id: SecureRandom.uuid,
                  line_number: 0,
                  expect: {status: 200}
                },
                {
                  id: SecureRandom.uuid,
                  line_number: 0,
                  expect: {status: 200}
                }
              ]
            },
            {
              id: SecureRandom.uuid,
              name: "spec_2",
              file_path: "",
              file_name: "specs",
              line_number: 0,
              url: "/specs_2",
              expectations: [
                {
                  id: SecureRandom.uuid,
                  line_number: 0,
                  expect: {status: 200}
                },
                {
                  id: SecureRandom.uuid,
                  line_number: 0,
                  expect: {status: 200}
                }
              ]
            }
          ]
        ],
        [
          {}, # Global
          {}, # Metadata
          [
            {
              id: SecureRandom.uuid,
              name: "other_spec_1",
              file_path: "",
              file_name: "other_specs",
              line_number: 0,
              url: "/other_specs",
              expectations: [
                {
                  id: SecureRandom.uuid,
                  line_number: 0,
                  expect: {status: 200}
                },
                {
                  id: SecureRandom.uuid,
                  line_number: 0,
                  expect: {status: 200}
                }
              ]
            },
            {
              id: SecureRandom.uuid,
              name: "other_spec_2",
              file_path: "",
              file_name: "other_specs",
              line_number: 0,
              url: "/other_specs_2",
              expectations: [
                {
                  id: SecureRandom.uuid,
                  name: "named_expectation",
                  line_number: 0,
                  expect: {status: 200}
                },
                {
                  id: SecureRandom.uuid,
                  line_number: 0,
                  expect: {status: 200}
                }
              ]
            }
          ]
        ]
      ]

      forges.each do |_g, _m, specs|
        specs.map! do |spec|
          SpecForge::Normalizer.normalize_spec!(spec, label: "spec \"#{spec[:name]}\"")
        end
      end

      forges.map { |f| SpecForge::Forge.new(*f) }
    end

    let(:file_name) {}
    let(:spec_name) {}
    let(:expectation_name) {}

    subject(:filtered) do
      described_class.apply(forges, file_name:, spec_name:, expectation_name:)
    end

    context "when filtering for a file" do
      let(:file_name) { "specs" }

      it "is expected to return the specs with the matching filename" do
        expect(filtered.size).to eq(1) # One file

        forge = filtered.first
        expect(forge.specs.size).to eq(2) # Two specs

        # Ensuring they were not modified
        expect(forge.specs.flat_map(&:expectations).size).to eq(4) # 2 each
      end
    end

    context "when filtering for a spec" do
      let(:file_name) { "specs" }
      let(:spec_name) { "spec_2" }

      it "is expected to return the specs with the matching spec name" do
        expect(filtered.size).to eq(1) # One file

        forge = filtered.first
        expect(forge.specs.size).to eq(1) # One spec

        # Ensuring they were not modified
        expect(forge.specs.flat_map(&:expectations).size).to eq(2)
      end
    end

    context "when filtering for an example" do
      let(:file_name) { "other_specs" }
      let(:spec_name) { "other_spec_2" }
      let(:expectation_name) { "GET /other_specs_2 - named_expectation" }

      it "is expected to return the specs with the matching spec name" do
        expect(filtered.size).to eq(1) # One file

        forge = filtered.first
        expect(forge.specs.size).to eq(1) # One spec

        # Ensuring they were modified
        expect(forge.specs.flat_map(&:expectations).size).to eq(1)
      end
    end

    context "when filtering by an expectation and the spec is not provided" do
      let(:expectation_name) { "GET /other_specs_2 - named_expectation" }

      it do
        expect { filtered }.to raise_error(ArgumentError)
      end
    end

    context "when filtering by a spec and the filename is not provided" do
      let(:spec_name) { "spec_2" }

      it do
        expect { filtered }.to raise_error(ArgumentError)
      end
    end
  end
end
