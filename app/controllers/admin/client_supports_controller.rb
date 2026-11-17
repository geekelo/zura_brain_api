class Admin::ClientSupportsController < ApplicationController
  def index
    if invalid_period?
      render json: { error: "Month and year are invalid" }, status: :bad_request
      return
    end

    supports = support_records

    render json: {
      "client_supports" => supports.map { |support| support_json(support) },
      "summaries" => summaries,
      "totals" => totals(supports)
    }, status: :ok
  end

  def create
    session_record = find_session
    return if session_record.nil?

    support = ClientSupport.new(client_support_params.merge(session: session_record))
    if support.save
      refresh_summary(support)
      render json: support_json(support), status: :created
    else
      render json: { errors: support.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    support = set_client_support
    return if support.nil?

    previous_period = period_for(support)
    if changing_session?
      session_record = find_session
      return if session_record.nil?

      support.session = session_record
    end

    if support.update(client_support_params)
      refresh_period(*previous_period)
      refresh_summary(support)
      render json: support_json(support), status: :ok
    else
      render json: { errors: support.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    support = set_client_support
    return if support.nil?

    previous_period = period_for(support)
    support.destroy
    refresh_period(*previous_period)
    render json: { message: "Client support deleted successfully" }, status: :ok
  end

  private

  def support_records
    records = ClientSupport.all
    records = records.in_month(params[:month], params[:year]) if period
    records.preload(session: :client).order(created_at: :desc)
  end

  def support_json(support)
    {
      "id" => support.id,
      "description" => support.description,
      "notes" => support.notes,
      "amount" => support.amount,
      "type" => support.type,
      "settled" => support.settled,
      "session_code" => support.session&.session_code,
      "client_name" => support.session&.client&.name,
      "created_at" => support.created_at&.utc&.iso8601(0)
    }
  end

  def summaries
    if period
      [summary_json(Pos::UpdateClientSupportSummary.call(month: params[:month], year: params[:year]))]
    else
      ClientSupportSummary.order(year: :desc, month: :desc).map { |summary| summary_json(summary) }
    end
  end

  def summary_json(summary)
    {
      "month" => summary.month,
      "year" => summary.year,
      "total_amount_payin" => summary.total_amount_payin,
      "amount_settled_payin" => summary.amount_settled_payin,
      "amount_unsettled_payin" => summary.amount_unsettled_payin,
      "total_amount_payout" => summary.total_amount_payout,
      "amount_settled_payout" => summary.amount_settled_payout,
      "amount_unsettled_payout" => summary.amount_unsettled_payout
    }
  end

  def totals(records)
    rows = records.to_a
    payins = rows.select { |row| row.type == "payin" }
    payouts = rows.select { |row| row.type == "payout" }
    {
      "total_amount_payin" => money_sum(payins),
      "amount_settled_payin" => money_sum(payins.select(&:settled)),
      "amount_unsettled_payin" => money_sum(payins.reject(&:settled)),
      "total_amount_payout" => money_sum(payouts),
      "amount_settled_payout" => money_sum(payouts.select(&:settled)),
      "amount_unsettled_payout" => money_sum(payouts.reject(&:settled))
    }
  end

  def money_sum(records)
    records.sum(0.to_d) { |record| record.amount.to_d }
  end

  def client_support_params
    params.require(:client_support).permit(:description, :notes, :amount, :type, :settled)
  end

  def set_client_support
    support = ClientSupport.find_by(id: params[:id])
    if support.nil?
      render json: { error: "Client support not found" }, status: :not_found
      return
    end
    support
  end

  def changing_session?
    payload.key?(:ss) || payload.key?(:session_code) || payload.key?(:session_id)
  end

  def find_session
    code = payload[:ss].presence || payload[:session_code].presence
    session_record = if code.present?
      Session.find_by(session_code: code)
    elsif payload[:session_id].present?
      Session.find_by(id: payload[:session_id])
    end

    if session_record.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end
    session_record
  end

  def payload
    params[:client_support].presence || ActionController::Parameters.new
  end

  def refresh_summary(support)
    refresh_period(*period_for(support))
  end

  def period_for(support)
    time = support.session&.session_date || support.created_at || Time.current
    [time.month, time.year]
  end

  def refresh_period(month, year)
    Pos::UpdateClientSupportSummary.call(month: month, year: year)
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
