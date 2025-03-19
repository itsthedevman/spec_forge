# frozen_string_literal: true

RSpec.describe SpecForge::Attribute::Chainable do
  let(:chainable_attribute) do
    stub_const(
      "ChainableAttribute",
      Class.new(SpecForge::Attribute) do
        include SpecForge::Attribute::Chainable

        def base_object
          {
            key_1: 2,
            nested: {
              key: "value",
              array: [1, 2, 3]
            },
            items: [
              {id: 1, name: "First"},
              {id: 2, name: "Second"}
            ],
            methods: OpenStruct.new(
              foo: Struct.new(:bar).new(bar: "baz"),
              hello: ->(name) { "Hello, #{name}!" }
            ),
            store: SpecForge::Context::Store::Entry.new(
              request: {},
              variables: {},
              response: {body: {id: ""}}
            )
          }
        end
      end
    )
  end

  subject(:attribute) { chainable_attribute.new(input) }

  context "when attempting to access a non-existent hash key" do
    let(:input) { "key.header.key_1.foo" }

    it "is expected to provide a helpful error message" do
      expect { attribute.value }.to raise_error(SpecForge::Error::InvalidInvocationError) do |e|
        expect(e.message).to eq <<~STRING
          Cannot invoke "foo" on Integer

          Resolution path:
          1. key.header --> Hash with keys: "key_1", "nested", "items", "methods", "store"
          2. key.header.key_1 --> Integer: 2
          3. key.header.key_1.foo --> Error: Cannot invoke "foo" on Integer
        STRING
      end
    end
  end

  context "when attempting to access a non-existent attribute on Store::Entry" do
    let(:input) { "key.header.store.body.name" }

    it "is expected to provide a helpful error message" do
      expect { attribute.value }.to raise_error(SpecForge::Error::InvalidInvocationError) do |e|
        expect(e.message).to eq <<~STRING
          Cannot invoke "name" on Hash

          Resolution path:
          1. key.header --> Hash with keys: "key_1", "nested", "items", "methods", "store"
          2. key.header.store --> Store with attributes: "scope", "request", "variables", "response", "status", "body", "headers"
          3. key.header.store.body --> Hash with key: "id"
          4. key.header.store.body.name --> Error: Cannot invoke "name" on Hash
        STRING
      end
    end
  end

  context "when attempting to access a non-existent attribute on Struct" do
    let(:input) { "key.header.methods.foo.baz" }

    it "is expected to provide a helpful error message" do
      expect { attribute.value }.to raise_error(SpecForge::Error::InvalidInvocationError) do |e|
        expect(e.message).to eq <<~STRING
          Cannot invoke "baz" on Struct

          Resolution path:
          1. key.header --> Hash with keys: "key_1", "nested", "items", "methods", "store"
          2. key.header.methods --> Object with attributes: "foo", "hello"
          3. key.header.methods.foo --> Object with attributes: "bar"
          4. key.header.methods.foo.baz --> Error: Cannot invoke "baz" on Struct
        STRING
      end
    end
  end

  context "when invoking a method on an array" do
    let(:input) { "key.header.items.size" }

    it "is expected to resolve the array method" do
      expect(attribute.value).to eq(2)
    end
  end

  context "when invoking an index on an array" do
    let(:input) { "key.header.items.0.name" }

    it "is expected to access the array index and then property" do
      expect(attribute.value).to eq("First")
    end
  end

  context "when trying to use a non-number on an array" do
    let(:input) { "key.header.items.invalid" }

    it "is expected to provide a helpful error" do
      expect { attribute.value }.to raise_error(SpecForge::Error::InvalidInvocationError) do |e|
        expect(e.message).to eq <<~STRING
          Cannot invoke "invalid" on Array

          Resolution path:
          1. key.header --> Hash with keys: "key_1", "nested", "items", "methods", "store"
          2. key.header.items --> Array with 2 elements: [Hash, Hash]
          3. key.header.items.invalid --> Error: Cannot invoke "invalid" on Array
        STRING
      end
    end
  end

  context "when invoking a property on a nil value" do
    let(:input) { "key.header.missing.property" }

    it "is expected to provide a helpful error about nil" do
      expect { attribute.value }.to raise_error(SpecForge::Error::InvalidInvocationError) do |e|
        expect(e.message).to eq <<~STRING
          Cannot invoke "missing" on Hash

          Resolution path:
          1. key.header --> Hash with keys: "key_1", "nested", "items", "methods", "store"
          2. key.header.missing --> Error: Cannot invoke "missing" on Hash
        STRING
      end
    end
  end

  context "with a complex nested path" do
    let(:input) { "key.header.nested.array.1" }

    it "is expected to resolve the nested path correctly" do
      expect(attribute.value).to eq(2)
    end
  end

  context "when invoking a chain that works until the last step" do
    let(:input) { "key.header.methods.hello.upcase" }

    it "is expected to provide a helpful error" do
      expect { attribute.value }.to raise_error(SpecForge::Error::InvalidInvocationError) do |e|
        expect(e.message).to match <<~STRING
          Cannot invoke "upcase" on Proc

          Resolution path:
          1. key.header --> Hash with keys: "key_1", "nested", "items", "methods", "store"
          2. key.header.methods --> Object with attributes: "foo", "hello"
          3. key.header.methods.hello --> Proc defined at .+chainable_spec.+
          4. key.header.methods.hello.upcase --> Error: Cannot invoke "upcase" on Proc
        STRING
      end
    end
  end
end
