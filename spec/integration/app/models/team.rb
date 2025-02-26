# frozen_string_literal: true

class Team < ApplicationRecord
  attribute :name, :string
  attribute :plan_type, :string, default: "free"

  has_many :users, dependent: :nullify

  validates :name, presence: true
  validates :plan_type, inclusion: {in: %w[free pro enterprise]}
end
