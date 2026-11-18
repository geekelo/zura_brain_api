class Admin::MainAccountsController < ApplicationController
  def index
    if invalid_period?
      render json: { error: "Month and year are invalid" }, status: :bad_request
      return
    end

    expenses = expense_records.select { |expense| expense.type.nil? || expense.type == "payout" }
    other_income = other_income_records

    render json: {
      "expenses" => expenses.map { |expense| expense_json(expense) },
      "other_income" => other_income.map { |support| income_json(support) },
      "summaries" => summaries,
      "totals" => {
        "expenses" => money_sum(expenses),
        "other_income" => money_sum(other_income)
      }
    }, status: :ok
  end

  private

  def expense_records
    records = MainAccountExpense.all
    records = records.where(created_at: period) if period
    records.order(created_at: :desc).to_a
  end

  def other_income_records
    records = ClientSupport.where(settled: true, account_type: "main", type: "payin").includes(session: :client)
    records = records.where(updated_at: period) if period
    records.order(updated_at: :desc)
  end

  def expense_json(expense)
    {
      "id" => expense.id,
      "amount" => expense.amount,
      "description" => expense.description,
      "type" => expense.type,
      "created_at" => expense.created_at&.utc&.iso8601(0)
    }
  end

  def income_json(support)
    {
      "id" => support.id,
      "description" => support.description,
      "amount" => support.amount,
      "client_name" => support.session&.client&.name,
      "client_phone" => support.session&.client&.phone,
      "session_code" => support.session&.session_code,
      "created_at" => support.updated_at&.utc&.iso8601(0)
    }
  end

  def summaries
    if period
      [summary_json(Pos::UpdateMainAccount.call(month: params[:month], year: params[:year]))]
    else
      MainAccount.order(year: :desc, month: :desc).map { |account| summary_json(account) }
    end
  end

  def summary_json(account)
    {
      "month" => account.month,
      "year" => account.year,
      "total_session_inflow" => account.total_session_inflow,
      "total_lunez_inflow" => account.total_lunez_inflow,
      "total_other_income" => other_income_total(account.month, account.year),
      "total_main_account_outflow" => account.total_main_account_outflow,
      "balance" => account.balance
    }
  end

  def other_income_total(month, year)
    return 0.to_d if month.blank? || year.blank?

    range = Date.new(year.to_i, month.to_i, 1).in_time_zone.all_month
    ClientSupport.where(settled: true, account_type: "main", type: "payin", updated_at: range).sum(:amount).to_d
  end

  def money_sum(records)
    records.to_a.sum(0.to_d) { |record| record.amount.to_d }
  end

  def requested_period?
    params[:month].present? || params[:year].present?
  end

  def invalid_period?
    return false unless requested_period?

    month = params[:month].to_s
    year = params[:year].to_s
    return true unless month.match?(/\A[1-9]\d?\z/) && year.match?(/\A[1-9]\d*\z/)

    !((1..12).cover?(month.to_i) && year.to_i.positive?)
  end

  def period
    return unless requested_period?

    Date.new(params[:year].to_i, params[:month].to_i, 1).in_time_zone.all_month
  end
end
