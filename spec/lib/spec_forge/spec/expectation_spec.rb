# frozen_string_literal: true

RSpec.describe SpecForge::Spec::Expectation do
  describe "#compile" do
    let(:input) {}
    let(:request) { SpecForge::Request.new }

    subject(:expectation) do
      described_class.new(input, "expectation_name", "/file/path")
        .compile(request)
    end

    context "when input is an empty hash" do
      let(:input) { {} }

      it do
        expect { expectation }.to raise_error(
          SpecForge::InvalidTypeError,
          "Expected Integer | String, got NilClass for 'status' on expectation"
        )
      end
    end

    context "when input is a valid hash" do
      let(:input) { {status: 404} }

      it "is expected to compile" do
        expect(expectation.status).to eq(404)
      end
    end

    context "when input is not a hash" do
      let(:input) { "" }

      it do
        expect { expectation }.to raise_error(
          SpecForge::InvalidTypeError,
          "Expected Hash, got String for expectation"
        )
      end
    end

    context "when 'name' is provided" do
      let(:input) { {status: 404, name: Faker::String.random} }

      it "is expected to rename the expectation" do
        expect(expectation.name).to eq(input[:name])
      end
    end

    context "when 'name' is not provided" do
      let(:input) { {status: 404} }

      it "is expected to have the same name" do
        expect(expectation.name).to eq("expectation_name")
      end
    end

    context "when 'status' is provided" do
      context "and it is a string" do
        let(:input) { {status: "404"} }

        it "is expected to convert the status to an integer" do
          expect(expectation.status).to eq(404)
        end
      end

      context "and it is a integer" do
        let(:input) { {status: 404} }

        it "is expected to store the status as an integer" do
          expect(expectation.status).to eq(404)
        end
      end

      context "and it is not a string or integer" do
        let(:input) { {status: []} }

        it do
          expect { expectation }.to raise_error(
            SpecForge::InvalidTypeError,
            "Expected Integer | String, got Array for 'status' on expectation"
          )
        end
      end
    end

    context "when 'variables' is provided" do
      context "and it is a hash" do
        let(:input) { {status: 404, variables: {foo: "bar"}} }

        it "is expected to convert the variable attributes" do
          expect(expectation.variables).to be_kind_of(ActiveSupport::HashWithIndifferentAccess)
          expect(expectation.variables[:foo]).to be_kind_of(SpecForge::Attribute::Literal)
        end
      end

      context "and it not a hash" do
        let(:input) { {status: 404, variables: ""} }

        it do
          expect { expectation }.to raise_error(
            SpecForge::InvalidTypeError,
            "Expected Hash, got String for 'variables' on expectation"
          )
        end
      end
    end

    context "when 'json' is provided" do
      context "and it is a hash" do
        let(:input) { {status: 404, json: {foo: "faker.string.random"}} }

        it "is expected to cover the json attributes" do
          expect(expectation.json).to be_kind_of(ActiveSupport::HashWithIndifferentAccess)
          expect(expectation.json[:foo]).to be_kind_of(SpecForge::Attribute::Faker)
        end
      end

      context "and it not a hash" do
        let(:input) { {status: 404, json: ""} }

        it do
          expect { expectation }.to raise_error(
            SpecForge::InvalidTypeError,
            "Expected Hash, got String for 'json' on expectation"
          )
        end
      end
    end

    context "when 'json' is not provided" do
      let(:input) { {status: 404} }

      it "is defaulted to an empty hash" do
        expect(expectation.json).to eq({})
      end
    end

    context "when 'body' is provided" do
      context "and it is a hash" do
        let(:request) do
          SpecForge::Request.new(body: {name: "Bob", email: "faker.internet.email"})
        end

        let(:input) { {status: 404, body: {name: "Billy"}} }

        it "is expected to clone the request and convert the body attributes" do
          expect(expectation.request.body[:name]).to eq("Billy")
          expect(request.body[:name]).to eq("Bob")
        end
      end

      context "and it not a hash" do
        let(:input) { {status: 404, body: ""} }

        it do
          expect { expectation }.to raise_error(
            SpecForge::InvalidTypeError,
            "Expected Hash, got String for 'body' on expectation"
          )
        end
      end
    end

    context "when 'body' is not provided" do
      let(:input) { {status: 404} }

      it "is defaulted to an empty hash" do
        expect(expectation.body).to eq({})
      end
    end

    context "when 'params' is provided" do
      context "and it is a hash" do
        let(:request) do
          SpecForge::Request.new(params: {id: 1})
        end

        let(:input) { {status: 404, params: {id: 2}} }

        it "is expected to clone the request and convert the body attributes" do
          expect(expectation.request.params[:id]).to eq(2)
          expect(request.params[:id]).to eq(1)
        end
      end

      context "and it not a hash" do
        let(:input) { {status: 404, params: ""} }

        it do
          expect { expectation }.to raise_error(
            SpecForge::InvalidTypeError,
            "Expected Hash, got String for 'params' on expectation"
          )
        end
      end
    end

    context "when 'params' is not provided" do
      let(:input) { {status: 404} }

      it "is defaulted to an empty hash" do
        expect(expectation.params).to eq({})
      end
    end
  end
end
