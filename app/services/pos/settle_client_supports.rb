module Pos
  class SettleClientSupports
    def self.call(ids:, description:)
      new(ids, description).call
    end

    def initialize(ids, description)
      @ids = Array(ids).map(&:to_i).uniq
      @description = description.to_s.strip
    end

    def call
      supports = ClientSupport.where(id: @ids).includes(:session).to_a
      error = validation_error(supports)
      return { error: error, status: error_status(error) } if error

      entry = nil
      ActiveRecord::Base.transaction do
        entry = create_entry(supports)
        supports.each { |support| support.update!(settled: true) }
      end

      refresh(supports, entry)
      { supports: supports, entry: entry }
    end

    private

    def validation_error(supports)
      return "Client supports are required" if @ids.empty?
      return "Client support not found" if supports.size != @ids.size
      return "Description is required" if @description.blank?
      return "Client support is settled" if supports.any?(&:settled?)
      return "Client supports must share one type" if supports.map(&:type).uniq.size != 1
      return "Client supports must share one account type" if supports.map(&:account_type).uniq.size != 1
      return "Account type is required" if supports.first.account_type.blank?

      nil
    end

    def error_status(error)
      error == "Client support not found" ? :not_found : :unprocessable_entity
    end

    def create_entry(supports)
      amount = supports.sum { |support| support.amount.to_d }
      account_type = supports.first.account_type
      entry_type = supports.first.type

      if account_type == "extra"
        ExtraAccount.create!(amount: amount, type: entry_type, description: @description)
      else
        MainAccountExpense.create!(amount: amount, type: entry_type, description: @description)
      end
    end

    def refresh(supports, entry)
      supports.map { |support| period_for(support) }.uniq.each do |month, year|
        UpdateClientSupportSummary.call(month: month, year: year)
      end

      if entry.is_a?(ExtraAccount)
        UpdateExtraAccountSummary.call(month: entry.created_at.month, year: entry.created_at.year)
      else
        UpdateMainAccount.call(month: entry.created_at.month, year: entry.created_at.year)
      end
    end

    def period_for(support)
      time = support.session&.session_date || support.created_at
      [time.month, time.year]
    end
  end
end
