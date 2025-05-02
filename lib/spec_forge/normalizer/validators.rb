# frozen_string_literal: true

module SpecForge
  class Normalizer
    #
    # Provides validation methods for Normalizer structures
    #
    # Contains validation functions that can be referenced by name
    # in structure definitions to perform custom validation logic.
    #
    # @example Validator in a structure definition
    #   http_verb: {type: String, validator: :http_verb}
    #
    class Validators
      #
      # Calls a validator method with the provided value and context
      #
      # @param method_name [Symbol, String] The validator method to call
      # @param value [Object] The value to validate
      # @param label [String] A descriptive label for error messages
      #
      # @return [void]
      #
      # @raise [Error] If validation fails
      #
      def self.call(method_name, value, label:)
        new(label).public_send(method_name, value)
      end

      #
      # Initializes a new validator instance with a context label
      #
      # @param label [String] A descriptive label for error messages
      #
      # @return [Validators] A new validator instance
      #
      def initialize(label)
        @label = label
      end

      #
      # Validates that a value is not blank
      #
      # Ensures the provided value is not nil, empty, or contains only whitespace.
      # This validator is useful for required fields that must have meaningful content.
      #
      # @param value [Object] The value to validate
      #
      # @raise [Error] If the value is blank
      #
      # @example Using the validator in a structure
      #   name: {type: String, validator: :present?}
      #
      def present?(value)
        raise Error, "Value cannot be blank for #{@label}" if value.blank?
      end

      #
      # Validates that a value is a supported HTTP verb
      #
      # Ensures the provided value is one of the supported HTTP methods
      # (GET, POST, PUT, PATCH, DELETE). Case-insensitive matching is used.
      #
      # @param value [String, Symbol, nil] The HTTP verb to validate, or nil
      #
      # @raise [Error] If the value is not a supported HTTP verb
      #
      # @example Using the validator in a structure
      #   http_verb: {type: String, validator: :http_verb}
      #
      def http_verb(value)
        valid_verbs = HTTP::Verb::VERBS.values.map(&:to_s)
        return if value.blank? || valid_verbs.include?(value.to_s.upcase)

        raise Error, "Invalid HTTP verb #{value.in_quotes} for #{@label}. Valid values are: #{valid_verbs.join_map(", ", &:in_quotes)}"
      end

      #
      # Validates that a callback is registered in the system
      #
      # Ensures the referenced callback name has been registered with SpecForge
      # before it's used in a test configuration.
      #
      # @param value [String, Symbol, nil] The callback name to validate, or nil
      #
      # @raise [Error::UndefinedCallbackError] If the callback is not registered
      #
      # @example Using the validator in a structure
      #   before_file: {type: String, validator: :callback}
      #
      def callback(value)
        return if value.blank?
        return if SpecForge::Callbacks.registered?(value)

        raise Error::UndefinedCallbackError.new(value, SpecForge::Callbacks.registered_names)
      end
    end
  end
end
