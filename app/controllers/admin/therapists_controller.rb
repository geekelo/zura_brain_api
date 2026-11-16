class Admin::TherapistsController < ApplicationController
  def index
    therapists = Therapist.all
    therapists = therapists.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params.key?(:active)
    # list active first and then inactive
    therapists = therapists.order(active: :desc)
    render json: therapists, status: :ok
  end

  def show
    therapist = find_therapist
    return if therapist.nil?
    if invalid_period?
      render json: { error: "Month and year are invalid" }, status: :bad_request
      return
    end

    render json: therapist.as_json.merge(
      "earnings" => earnings(therapist),
      "account_summaries" => account_summaries(therapist)
    ), status: :ok
  end

  def create
    return unless admin?

    therapist = Therapist.new(therapist_params)
    if therapist.save
      render json: therapist, status: :created
    else
      render json: { errors: therapist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_status
    return unless admin?

    therapist = find_therapist
    return if therapist.nil?

    if therapist.update(active: ActiveModel::Type::Boolean.new.cast(params[:active]))
      render json: therapist, status: :ok
    else
      render json: { errors: therapist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def find_therapist
    therapist = Therapist.find_by(code: params[:code])
    if therapist.nil?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end
    therapist
  end

  def admin?
    return true if AdminCode.matches?(params[:tc])

    render json: { error: "Not authorized" }, status: :unauthorized
    false
  end

  def therapist_params
    params.require(:therapist).permit(:work_name, :code, :avatar, :url, :active)
  end

  def earnings(therapist)
    session_links = therapist.session_therapists.includes(:session).joins(:session)
    session_links = session_links.where(sessions: { session_date: period }) if period
    session_links = session_links.order("sessions.session_date DESC")
    payins = therapist_entries(therapist, "payin")
    payouts = therapist_entries(therapist, "payout")

    {
      "session_therapist" => session_links.map { |link| session_therapist_earning(link) },
      "payins" => payins.map(&:as_json),
      "payouts" => payouts.map(&:as_json),
      "totals" => {
        "session_therapist" => session_links.sum { |link| link.tip_balance.to_d },
        "payins" => payins.sum { |entry| entry.amount.to_d },
        "payouts" => payouts.sum { |entry| entry.amount.to_d }
      }
    }
  end

  def session_therapist_earning(link)
    {
      "role" => link.role,
      "tip_amount" => link.tip_amount,
      "tip_balance" => link.tip_balance,
      "session_code" => link.session&.session_code,
      "session_date" => link.session&.session_date,
      "cycle" => link.session&.cycle,
      "cycle_length" => link.session&.cycle_length
    }
  end

  def therapist_entries(therapist, entry_type)
    entries = TherapistPayinsPayout.where(therapist: therapist, type: entry_type)
    entries = entries.where(created_at: period) if period
    entries.order(created_at: :desc)
  end

  def account_summaries(therapist)
    if period
      summary = Pos::UpdateTherapistAccount.call(
        therapist: therapist,
        month: params[:month],
        year: params[:year]
      )
      [summary.as_json]
    else
      TherapistAccount.where(therapist: therapist).order(year: :desc, month: :desc).map(&:as_json)
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
