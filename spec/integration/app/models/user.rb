# frozen_string_literal: true

class User < ApplicationRecord
  attribute :name, :string
  attribute :email, :string
  attribute :role, :string, default: "user"
  attribute :active, :boolean, default: true

  has_many :api_tokens, dependent: :destroy
  has_many :posts, foreign_key: :author_id, dependent: :destroy
  has_many :comments, foreign_key: :author_id, dependent: :destroy
  has_many :reviews, foreign_key: :reviewer_id, dependent: :destroy
  has_many :reviewed_posts, through: :reviews, source: :post

  belongs_to :team, optional: true

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
  validates :role, inclusion: {in: %w[admin user moderator]}
end
