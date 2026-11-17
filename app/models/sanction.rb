class Sanction < ApplicationRecord
  self.inheritance_column = :_type_disabled

  TYPES = %w[payin payout].freeze

  belongs_to :therapist, optional: true

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :type, inclusion: { in: TYPES }
end
