# frozen_string_literal: true

class Review < ApplicationRecord
  attribute :status, :string, default: "pending"
  attribute :notes, :string

  belongs_to :reviewer, class_name: "User"
  belongs_to :post

  validates :reviewer, presence: true
  validates :post, presence: true
  validates :status, inclusion: {in: %w[pending approved rejected]}

  # Ensure a user can't review the same post twice
  validates :reviewer_id, uniqueness: {scope: :post_id}
end
