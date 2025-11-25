# frozen_string_literal: true

module SpecForge
  class Normalizer
    class Transformers
      include Singleton

      def self.call(method_name, value)
        instance.public_send(method_name, value)
      end

      def normalize_includes(value)
        Array(value).map! { |name| name.delete_suffix(".yml").delete_suffix(".yaml") }
      end
    end
  end
end
