# app/models/user.rb
class User < ApplicationRecord
  # Attributes
  attribute :name, :string
  attribute :email, :string
  attribute :role, :string, default: "user"
  attribute :active, :boolean, default: true
  attribute :password, :string # Do not do in production!

  # Associations
  has_many :api_tokens, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :role, inclusion: {in: %w[admin user]}
  validates :password, presence: true, on: :create

  # For demo purposes, we'll use a very simple password authentication
  # In a real app, use has_secure_password or devise!
  def authenticate(password_attempt)
    password == password_attempt
  end
end
