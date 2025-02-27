# frozen_string_literal: true

class Post < ApplicationRecord
  attribute :title, :string
  attribute :content, :string
  attribute :category, :string
  attribute :status, :string, default: "draft"

  has_many :comments, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :reviewers, through: :reviews

  belongs_to :author, class_name: "User"

  validates :title, presence: true
  validates :author, presence: true
  validates :status, inclusion: {in: %w[draft published archived]}
end
