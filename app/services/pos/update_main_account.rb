module Pos
  class UpdateMainAccount
    def self.call(month:, year:)
      new(month, year).call
    end

    def initialize(month, year)
      @month = month.to_i
      @year = year.to_i
    end

    def call
      total_session_inflow = Session.where(session_date: period).sum(:amount).to_d
      total_lunez_inflow = Session.where(lunez: true, session_date: period).sum(:lunez_amount).to_d
      total_other_income = ClientSupport.where(
        settled: true,
        account_type: "main",
        type: "payin",
        updated_at: period
      ).sum(:amount).to_d
      total_main_account_outflow = MainAccountExpense.where(created_at: period, type: [nil, "payout"]).sum(:amount).to_d
      balance = total_session_inflow + total_lunez_inflow + total_other_income - total_main_account_outflow

      account = MainAccount.find_or_initialize_by(month: @month, year: @year)
      account.update!(
        total_session_inflow: total_session_inflow,
        total_lunez_inflow: total_lunez_inflow,
        total_main_account_outflow: total_main_account_outflow,
        balance: balance
      )
      account
    end

    private

    def period
      Date.new(@year, @month, 1).in_time_zone.all_month
    end
  end
end
