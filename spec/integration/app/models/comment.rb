# frozen_string_literal: true

class Comment < ApplicationRecord
  attribute :content, :string

  belongs_to :post
  belongs_to :author, class_name: "User"

  validates :content, presence: true
  validates :author, presence: true
  validates :post, presence: true
end
