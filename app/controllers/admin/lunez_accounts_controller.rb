class Admin::LunezAccountsController < ApplicationController
  def index
    if invalid_period?
      render json: { error: "Month and year are invalid" }, status: :bad_request
      return
    end

    inflows = inflow_records

    render json: {
      "inflows" => inflows.map { |session| inflow_json(session) },
      "summaries" => summaries,
      "totals" => {
        "inflows" => money_sum(inflows)
      }
    }, status: :ok
  end

  private

  def inflow_records
    records = Session.includes(:client).where(lunez: true)
    records = records.where(session_date: period) if period
    records.order(session_date: :desc)
  end

  def inflow_json(session)
    {
      "session_code" => session.session_code,
      "client_name" => session.client&.name,
      "lunez_amount" => session.lunez_amount,
      "session_date" => session.session_date&.utc&.iso8601(0)
    }
  end

  def summaries
    if period
      [summary_json(Pos::UpdateLunezAccount.call(month: params[:month], year: params[:year]))]
    else
      LunezAccount.order(year: :desc, month: :desc).map { |account| summary_json(account) }
    end
  end

  def summary_json(account)
    {
      "month" => account.month,
      "year" => account.year,
      "total_inflow" => account.total_inflow,
      "balance" => account.balance
    }
  end

  def money_sum(records)
    records.to_a.sum(0.to_d) { |record| record.lunez_amount.to_d }
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
