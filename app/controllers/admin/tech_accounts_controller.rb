class Admin::TechAccountsController < ApplicationController
  def index
    if invalid_period?
      render json: { error: "Month and year are invalid" }, status: :bad_request
      return
    end

    payins = entries("payin")
    payouts = entries("payout")

    render json: {
      "payins" => payins.map { |entry| entry_json(entry) },
      "payouts" => payouts.map { |entry| entry_json(entry) },
      "summaries" => summaries,
      "totals" => {
        "payins" => money_sum(payins),
        "payouts" => money_sum(payouts)
      }
    }, status: :ok
  end

  private

  def entries(entry_type)
    records = TechPayinsPayout.includes(extra_account: { session_therapist: [:session, :therapist] }).where(type: entry_type)
    records = records.where(created_at: period) if period
    records.order(created_at: :desc)
  end

  def entry_json(entry)
    session_therapist = entry.extra_account&.session_therapist

    {
      "amount" => entry.amount,
      "type" => entry.type,
      "description" => entry.description,
      "created_at" => entry.created_at&.utc&.iso8601(0),
      "session_code" => session_therapist&.session&.session_code,
      "therapist_name" => session_therapist&.therapist&.work_name
    }
  end

  def summaries
    if period
      [summary_json(Pos::UpdateTechAccountSummary.call(month: params[:month], year: params[:year]))]
    else
      TechAccountSummary.order(year: :desc, month: :desc).map { |summary| summary_json(summary) }
    end
  end

  def summary_json(summary)
    {
      "month" => summary.month,
      "year" => summary.year,
      "total_tech_payin" => summary.total_tech_payin,
      "total_tech_payout" => summary.total_tech_payout,
      "balance" => summary.balance
    }
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
