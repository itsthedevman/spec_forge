# frozen_string_literal: true

class ApiToken < ApplicationRecord
  before_validation :generate_token, on: :create

  attribute :token, :string

  belongs_to :user

  validates :token, presence: true, uniqueness: true

  private

  def generate_token
    return if token.present?
    self.token = SecureRandom.hex(16)
  end
end
