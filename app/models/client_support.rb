class ClientSupport < ApplicationRecord
  self.inheritance_column = :_type_disabled

  TYPES = %w[payin payout].freeze

  belongs_to :session

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :type, inclusion: { in: TYPES }

  scope :in_month, ->(month, year) { occurring_in(month, year) }

  def self.occurring_in(month, year)
    range = Date.new(year.to_i, month.to_i, 1).in_time_zone.all_month
    left_joins(:session).where(
      "COALESCE(sessions.session_date, client_supports.created_at) BETWEEN ? AND ?",
      range.begin,
      range.end
    )
  end
end
