module Pos
  class UpdateTechAccountSummary
    def self.call(month:, year:)
      new(month, year).call
    end

    def initialize(month, year)
      @month = month.to_i
      @year = year.to_i
    end

    def call
      total_tech_payin = sum_amounts("payin")
      total_tech_payout = sum_amounts("payout")
      balance = total_tech_payin - total_tech_payout

      summary = TechAccountSummary.find_or_initialize_by(month: @month, year: @year)
      summary.update!(
        total_tech_payin: total_tech_payin,
        total_tech_payout: total_tech_payout,
        balance: balance
      )
      summary
    end

    private

    def sum_amounts(entry_type)
      TechPayinPayout
        .where(type: entry_type, created_at: period)
        .sum(:amount)
        .to_d
    end

    def period
      Date.new(@year, @month, 1).in_time_zone.all_month
    end
  end
end
