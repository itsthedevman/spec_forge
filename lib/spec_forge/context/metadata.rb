# frozen_string_literal: true

module SpecForge
  class Context
    class Metadata < Context
      def initialize(**metadata)
        clear
        metadata.each { |k, v| store(k, v) }
      end

      def clear
        @inner = {
          file_name: "",
          file_path: "",
          relative_path: ""
        }

        @inner.transform_values { |v| Settable.new(v) }
      end

      def store(namespace, *value)
        namespace = retrieve_namespace(namespace)
        namespace.set(value)
      end

      def retrieve(namespace, key = nil)
        namespace = retrieve_namespace(namespace)
        return namespace unless namespace.is_a?(Hash)

        namespace[key]
      end

      private

      def retrieve_namespace(name)
        namespace = @inner[name.to_sym]

        if namespace.nil?
          namespaces = @inner.keys.join_map(", ", &:in_quotes)

          raise ArgumentError,
            "Invalid namespace for Metadata context. Expected one of #{namespaces}. Got #{name}"
        end

        namespace
      end
    end
  end
end
