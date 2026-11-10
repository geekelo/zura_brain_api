module Pos
  class UpdateTherapistAccount
    PAYOUT_TYPES = %w[payin payout].freeze

    def self.call(therapist:, month:, year:)
      new(therapist, month, year).call
    end

    def initialize(therapist, month, year)
      @therapist = therapist
      @month = month.to_i
      @year = year.to_i
    end

    def call
      total_therapist_payin = sum_amounts("payin")
      total_tip_inflow = total_tip_balance
      total_therapist_payout = sum_amounts("payout")
      balance = total_therapist_payin + total_tip_balance - total_therapist_payout

      account = TherapistAccount.find_or_initialize_by(
        therapist: @therapist,
        month: @month,
        year: @year
      )
      account.update!(
        total_therapist_payin: total_therapist_payin,
        total_tip_balance: total_tip_balance,
        total_therapist_payout: total_therapist_payout,
        balance: balance
      )
      account
    end

    private

    def sum_amounts(entry_type)
      TherapistPayinPayout
        .where(therapist: @therapist, type: entry_type, created_at: period)
        .sum(:amount)
        .to_d
    end

    def total_tip_balance
      SessionTherapist
        .joins(:session)
        .where(therapist: @therapist, sessions: { session_date: period })
        .sum(:tip_balance)
        .to_d
    end

    def period
      Date.new(@year, @month, 1).in_time_zone.all_month
    end
  end
end
