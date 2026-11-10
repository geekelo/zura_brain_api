module Pos
  class UpdateExtraAccountSummary
    def self.call(month:, year:)
      new(month, year).call
    end

    def initialize(month, year)
      @month = month.to_i
      @year = year.to_i
    end

    def call
      total_extra_account_inflow = sum_amounts("payin")
      total_extra_account_outflow = sum_amounts("payout")
      balance = total_extra_account_inflow - total_extra_account_outflow

      summary = ExtraAccountSummary.find_or_initialize_by(month: @month, year: @year)
      summary.update!(
        total_extra_account_inflow: total_extra_account_inflow,
        total_extra_account_outflow: total_extra_account_outflow,
        balance: balance
      )
      summary
    end

    private

    def sum_amounts(entry_type)
      ExtraAccountPayinPayout
        .where(type: entry_type, created_at: period)
        .sum(:amount)
        .to_d
    end

    def period
      Date.new(@year, @month, 1).in_time_zone.all_month
    end
  end
end
