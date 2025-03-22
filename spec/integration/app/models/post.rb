# frozen_string_literal: true

class Post < ApplicationRecord
  # Attributes
  attribute :title, :string
  attribute :content, :text
  attribute :published, :boolean, default: false

  # Validations
  validates :title, presence: true
  validates :content, presence: true
  validates :user_id, presence: true

  # Associations
  belongs_to :user
  has_many :comments, dependent: :destroy
end
