module Pos
  class SyncStakesAccount
    RATE = BigDecimal("0.2")

    def self.call(session)
      new(session).call
    end

    def initialize(session)
      @session = session
    end

    def call
      amount = (@session.amount.to_d * RATE).round(2)
      stake = @session.stakes_accounts.order(:id).first

      if amount <= 0
        stake&.destroy
        return
      end

      stake ||= @session.stakes_accounts.build
      stake.update!(amount: amount)
    end
  end
end
