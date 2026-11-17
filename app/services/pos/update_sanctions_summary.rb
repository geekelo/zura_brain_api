module Pos
  class UpdateSanctionsSummary
    def self.call(month:, year:)
      new(month, year).call
    end

    def initialize(month, year)
      @month = month.to_i
      @year = year.to_i
    end

    def call
      records = sanctions_in_month
      total_payin = sum_amount(records.where(type: "payin"))
      total_payout = sum_amount(records.where(type: "payout"))

      summary = SanctionsSummary.find_or_initialize_by(month: @month, year: @year)
      summary.update!(
        total_payin: total_payin,
        total_payout: total_payout,
        total_balance: total_payin - total_payout
      )
      summary
    end

    private

    def sanctions_in_month
      range = Date.new(@year, @month, 1).in_time_zone.all_month
      Sanction.where(created_at: range)
    end

    def sum_amount(records)
      records.sum(:amount).to_d
    end
  end
end
