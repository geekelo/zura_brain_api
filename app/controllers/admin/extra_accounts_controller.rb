class Admin::ExtraAccountsController < ApplicationController
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
        "payins" => payins.sum { |entry| entry.amount.to_d },
        "payouts" => payouts.sum { |entry| entry.amount.to_d }
      }
    }, status: :ok
  end

  private

  def entries(entry_type)
    records = ExtraAccount.includes(session_therapist: [:session, :therapist]).where(type: entry_type)
    records = records.where(created_at: period) if period
    records.order(created_at: :desc)
  end

  def entry_json(entry)
    {
      "amount" => entry.amount,
      "type" => entry.type,
      "description" => entry.description,
      "created_at" => entry.created_at,
      "session_code" => entry.session_therapist&.session&.session_code,
      "therapist_name" => entry.session_therapist&.therapist&.work_name
    }
  end

  def summaries
    if period
      [Pos::UpdateExtraAccountSummary.call(month: params[:month], year: params[:year]).as_json]
    else
      ExtraAccountSummary.order(year: :desc, month: :desc).map(&:as_json)
    end
  end

  def requested_period?
    params[:month].present? || params[:year].present?
  end

  def invalid_period?
    return false unless requested_period?

    month = params[:month].to_i
    year = params[:year].to_i
    !((1..12).cover?(month) && year.positive?)
  end

  def period
    return unless requested_period?

    Date.new(params[:year].to_i, params[:month].to_i, 1).in_time_zone.all_month
  end
end
