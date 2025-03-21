# frozen_string_literal: true

class Comment < ApplicationRecord
  # Attributes
  attribute :content, :text

  # Validations
  validates :content, presence: true
  validates :user_id, presence: true
  validates :post_id, presence: true

  # Associations
  belongs_to :post
  belongs_to :user
end
