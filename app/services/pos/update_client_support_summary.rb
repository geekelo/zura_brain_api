module Pos
  class UpdateClientSupportSummary
    def self.call(month:, year:)
      new(month, year).call
    end

    def initialize(month, year)
      @month = month.to_i
      @year = year.to_i
    end

    def call
      records = ClientSupport.occurring_in(@month, @year)
      payins = records.where(type: "payin")
      payouts = records.where(type: "payout")
      summary = ClientSupportSummary.find_or_initialize_by(month: @month, year: @year)
      summary.update!(
        total_amount_payin: sum_amount(payins),
        amount_settled_payin: sum_amount(payins.where(settled: true)),
        amount_unsettled_payin: sum_amount(payins.where(settled: false)),
        total_amount_payout: sum_amount(payouts),
        amount_settled_payout: sum_amount(payouts.where(settled: true)),
        amount_unsettled_payout: sum_amount(payouts.where(settled: false))
      )
      summary
    end

    private

    def sum_amount(records)
      records.sum("client_supports.amount").to_d
    end
  end
end
