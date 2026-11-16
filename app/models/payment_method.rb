class PaymentMethod < ApplicationRecord
  self.inheritance_column = :_type_disabled

  belongs_to :session

  STATUSES = %w[refunded ok nonrefunded].freeze

  scope :active, -> { where(deleted_at: nil) }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
end
