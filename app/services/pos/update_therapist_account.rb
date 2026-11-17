module Pos
  class UpdateTherapistAccount
    PAYOUT_TYPES = %w[payin payout].freeze

    def self.call(therapist:, month:, year:, exclude_sanction: nil)
      new(therapist, month, year, exclude_sanction).call
    end

    def initialize(therapist, month, year, exclude_sanction = nil)
      @therapist = therapist
      @month = month.to_i
      @year = year.to_i
      @exclude_sanction = exclude_sanction
    end

    def call
      total_therapist_payin = sum_amounts("payin") + sum_sanctions("payin")
      total_therapist_payout = sum_amounts("payout") + sum_sanctions("payout")
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
      TherapistPayinsPayout
        .where(therapist: @therapist, type: entry_type, created_at: period)
        .sum(:amount)
        .to_d
    end

    def sum_sanctions(entry_type)
      sanctions = Sanction.where(therapist: @therapist, type: entry_type, created_at: period)
      sanctions = sanctions.where.not(id: @exclude_sanction.id) if @exclude_sanction&.type == entry_type
      sanctions.sum(:amount).to_d
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
