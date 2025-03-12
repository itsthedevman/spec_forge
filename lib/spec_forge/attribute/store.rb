# frozen_string_literal: true

module SpecForge
  class Attribute
    #
    # Represents an attribute that references values from stored test results
    #
    # This class allows accessing data from previous test executions that were
    # saved using the `store_as` directive. It provides access to response data
    # including status, headers, and body from previously run expectations.
    #
    # @example Basic usage in YAML
    #   create_user:
    #     path: /users
    #     method: post
    #     expectations:
    #     - store_as: new_user
    #       body:
    #         name: faker.name.name
    #       expect:
    #         status: 201
    #
    #   get_user:
    #     path: /users/{id}
    #     expectations:
    #     - query:
    #         id: store.new_user.body.id
    #       expect:
    #         status: 200
    #
    # @example Accessing specific response components
    #   check_status:
    #     path: /health
    #     expectations:
    #     - variables:
    #         expected_status: store.new_user.status
    #         auth_token: store.new_user.headers.authorization
    #         user_name: store.new_user.body.user.name
    #       expect:
    #         status: 200
    #
    class Store < Attribute
      include Chainable

      #
      # Regular expression pattern that matches attribute keywords with this prefix
      # Used for identifying this attribute type during parsing
      #
      # @return [Regexp]
      #
      KEYWORD_REGEX = /^store\./i

      alias_method :stored_id, :header

      #
      # Returns the base object for the variable chain
      #
      # @return [Context::Store::Entry, nil] The stored entry or nil if not found
      #
      def base_object
        @base_object ||= SpecForge.context.store[stored_id.to_s]
      end
    end
  end
end
