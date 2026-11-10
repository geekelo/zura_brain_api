module Pos
  class UpdateLunezAccount
    def self.call(month:, year:)
      new(month, year).call
    end

    def initialize(month, year)
      @month = month.to_i
      @year = year.to_i
    end

    def call
      total_inflow = Session.where(lunez: true, session_date: period).sum(:lunez_amount).to_d
      balance = total_inflow

      account = LunezAccount.find_or_initialize_by(month: @month, year: @year)
      account.update!(
        total_inflow: total_inflow,
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
