# frozen_string_literal: true

class User < ApplicationRecord
  # Attributes
  attribute :name, :string
  attribute :email, :string
  attribute :role, :string, default: "user"
  attribute :active, :boolean, default: true

  # Associations
  has_many :api_tokens, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: %w[admin user] }
end
