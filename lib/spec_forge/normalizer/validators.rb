# frozen_string_literal: true

module SpecForge
  class Normalizer
    class Validators
      include Singleton

      def self.call(method_name, value)
        instance.public_send(method_name, value)
      end

      def present?(value)
        raise Error, "Value cannot be blank" if value.blank?
      end

      def http_verb(value)
        valid_verbs = HTTP::Verb::VERBS.values
        return if value.blank? || valid_verbs.include?(value.to_s.upcase)

        raise Error, "Invalid HTTP verb: #{value}. Valid values are: #{valid_verbs.join(", ")}"
      end

      def callback(value)
        return if value.blank?
        return if SpecForge::Callbacks.registered?(value)

        raise Error::UndefinedCallbackError.new(value, SpecForge::Callbacks.registered_names)
      end
    end
  end
end
