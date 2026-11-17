class ClientSupport < ApplicationRecord
  self.inheritance_column = :_type_disabled

  TYPES = %w[payin payout].freeze
  ACCOUNT_TYPES = %w[main extra].freeze

  belongs_to :session

  validates :description, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :type, inclusion: { in: TYPES }
  validates :account_type, inclusion: { in: ACCOUNT_TYPES }, allow_nil: true
  validate :remains_open, on: :update

  before_validation :normalize_account_type

  scope :in_month, ->(month, year) { occurring_in(month, year) }

  def self.occurring_in(month, year)
    range = Date.new(year.to_i, month.to_i, 1).in_time_zone.all_month
    left_joins(:session).where(
      "COALESCE(sessions.session_date, client_supports.created_at) BETWEEN ? AND ?",
      range.begin,
      range.end
    )
  end

  private

  def normalize_account_type
    text = account_type.to_s.strip.downcase
    text = "extra" if text == "extra account"
    self.account_type = text.presence
  end

  def remains_open
    return unless settled_in_database

    errors.add(:base, "Client support is settled")
  end
end
