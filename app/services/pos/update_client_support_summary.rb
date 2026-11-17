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
      summary = ClientSupportSummary.find_or_initialize_by(month: @month, year: @year)
      summary.update!(
        total_amount: sum_amount(records),
        amount_settled: sum_amount(records.where(settled: true)),
        amount_unsettled: sum_amount(records.where(settled: false))
      )
      summary
    end

    private

    def sum_amount(records)
      records.sum("client_supports.amount").to_d
    end
  end
end
