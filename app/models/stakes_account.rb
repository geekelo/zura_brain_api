class StakesAccount < ApplicationRecord
  belongs_to :session

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validate :remains_open, on: :update

  scope :in_month, ->(month, year) { occurring_in(month, year) }

  def self.occurring_in(month, year)
    range = Date.new(year.to_i, month.to_i, 1).in_time_zone.all_month
    left_joins(:session).where(
      "COALESCE(sessions.session_date, stakes_accounts.created_at) BETWEEN ? AND ?",
      range.begin,
      range.end
    )
  end

  private

  def remains_open
    return unless settled_in_database

    errors.add(:base, "Stake is settled")
  end
end
