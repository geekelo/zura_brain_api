module Pos
  class SettleStakesAccounts
    def self.call(ids:, description:)
      new(ids, description).call
    end

    def initialize(ids, description)
      @ids = Array(ids).map(&:to_i).uniq
      @description = description.to_s.strip
    end

    def call
      accounts = StakesAccount.where(id: @ids).includes(:session).to_a
      error = validation_error(accounts)
      return { error: error, status: error_status(error) } if error

      entry = nil
      ActiveRecord::Base.transaction do
        entry = MainAccountExpense.create!(
          amount: accounts.sum { |account| account.amount.to_d },
          type: "payout",
          description: @description
        )
        accounts.each { |account| account.update!(settled: true) }
      end

      refresh(accounts, entry)
      { accounts: accounts, entry: entry }
    end

    private

    def validation_error(accounts)
      return "Stakes are required" if @ids.empty?
      return "Stake not found" if accounts.size != @ids.size
      return "Description is required" if @description.blank?
      return "Stake is settled" if accounts.any?(&:settled?)

      nil
    end

    def error_status(error)
      error == "Stake not found" ? :not_found : :unprocessable_entity
    end

    def refresh(accounts, entry)
      accounts.map { |account| period_for(account) }.uniq.each do |month, year|
        UpdateStakesAccountSummary.call(month: month, year: year)
      end
      UpdateMainAccount.call(month: entry.created_at.month, year: entry.created_at.year)
    end

    def period_for(account)
      time = account.session&.session_date || account.created_at
      [time.month, time.year]
    end
  end
end
