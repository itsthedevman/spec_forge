# frozen_string_literal: true

module SpecForge
  class Normalizer
    class Validators
      def self.call(method_name, value, label:)
        new(label).public_send(method_name, value)
      end

      def initialize(label)
        @label = label
      end

      def present?(value)
        raise Error, "Value cannot be blank for #{@label}" if value.blank?
      end

      def http_verb(value)
        valid_verbs = HTTP::Verb::VERBS.values
        return if value.blank? || valid_verbs.include?(value.to_s.upcase)

        raise Error, "Invalid HTTP verb #{value.inspect.in_quotes} for #{@label}. Valid values are: #{valid_verbs.join_map(", ", &:in_quotes)}"
      end

      def callback(value)
        return if value.blank?
        return if SpecForge::Callbacks.registered?(value)

        raise Error::UndefinedCallbackError.new(value, SpecForge::Callbacks.registered_names)
      end
    end
  end
end
