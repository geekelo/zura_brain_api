class Admin::SanctionsController < ApplicationController
  def index
    if invalid_period?
      render json: { error: "Month and year are invalid" }, status: :bad_request
      return
    end

    sanctions = sanction_records

    render json: {
      "sanctions" => sanctions.map { |sanction| sanction_json(sanction) },
      "summaries" => summaries
    }, status: :ok
  end

  def create
    therapist = assigned_therapist
    return if performed?

    sanction = Sanction.new(sanction_params)
    sanction.therapist = therapist
    if sanction.save
      refresh_summary(sanction)
      refresh_therapist_account(sanction.therapist, sanction.created_at)
      render json: sanction_json(sanction), status: :created
    else
      render json: { errors: sanction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    sanction = set_sanction
    return if sanction.nil?

    previous_therapist = sanction.therapist
    previous_time = sanction.created_at

    if changing_therapist?
      therapist = assigned_therapist
      return if performed?

      sanction.therapist = therapist
    end

    if sanction.update(sanction_params)
      refresh_summary(sanction)
      refresh_therapist_account(previous_therapist, previous_time)
      refresh_therapist_account(sanction.therapist, sanction.created_at)
      render json: sanction_json(sanction), status: :ok
    else
      render json: { errors: sanction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    sanction = set_sanction
    return if sanction.nil?

    therapist = sanction.therapist
    created_at = sanction.created_at
    sanction.destroy
    Pos::UpdateSanctionsSummary.call(month: created_at.month, year: created_at.year)
    refresh_therapist_account(therapist, created_at)
    render json: { message: "Sanction deleted successfully" }, status: :ok
  end

  private

  def sanction_json(sanction)
    {
      "id" => sanction.id,
      "description" => sanction.description,
      "amount" => sanction.amount,
      "type" => sanction.type,
      "therapist_name" => sanction.therapist&.work_name,
      "therapist_code" => sanction.therapist&.code,
      "non_therapist" => sanction.non_therapist,
      "created_at" => sanction.created_at&.utc&.iso8601(0)
    }
  end

  def sanction_params
    params.require(:sanction).permit(:description, :amount, :type, :non_therapist)
  end

  def set_sanction
    sanction = Sanction.find_by(id: params[:id])
    if sanction.nil?
      render json: { error: "Sanction not found" }, status: :not_found
      return
    end
    sanction
  end

  def changing_therapist?
    payload.key?(:th) || payload.key?(:therapist_code) || payload.key?(:therapist_id)
  end

  def assigned_therapist
    return nil if therapist_code.blank? && payload[:therapist_id].blank?

    therapist = if therapist_code.present?
      Therapist.find_by(code: therapist_code)
    else
      Therapist.find_by(id: payload[:therapist_id])
    end

    if therapist.nil?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end
    therapist
  end

  def therapist_code
    payload[:th].presence || payload[:therapist_code].presence
  end

  def payload
    params[:sanction].presence || ActionController::Parameters.new
  end

  def sanction_records
    records = Sanction.includes(:therapist)
    records = records.where(created_at: period) if period
    records.order(created_at: :desc)
  end

  def summaries
    if period
      [summary_json(Pos::UpdateSanctionsSummary.call(month: params[:month], year: params[:year]))]
    else
      SanctionsSummary.order(year: :desc, month: :desc).map { |summary| summary_json(summary) }
    end
  end

  def summary_json(summary)
    {
      "month" => summary.month,
      "year" => summary.year,
      "total_payin" => summary.total_payin,
      "total_payout" => summary.total_payout,
      "total_balance" => summary.total_balance
    }
  end

  def refresh_summary(sanction)
    Pos::UpdateSanctionsSummary.call(month: sanction.created_at.month, year: sanction.created_at.year)
  end

  def refresh_therapist_account(therapist, time)
    return if therapist.nil? || time.nil?

    Pos::UpdateTherapistAccount.call(therapist: therapist, month: time.month, year: time.year)
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
