class Admin::TherapistPayinsPayoutsController < ApplicationController
  def create
    therapist = assigned_therapist
    return if performed?

    therapist_payin_payout = TherapistPayinsPayout.new(therapist_payin_payout_params.merge(therapist: therapist))
    if therapist_payin_payout.save
      refresh_therapist_account(therapist_payin_payout)
      render json: entry_json(therapist_payin_payout), status: :created
    else
      render json: { errors: therapist_payin_payout.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    therapist_payin_payout = set_therapist_payin_payout
    return if therapist_payin_payout.nil?

    previous_therapist = therapist_payin_payout.therapist
    previous_time = therapist_payin_payout.created_at

    if changing_therapist?
      therapist = assigned_therapist
      return if performed?

      therapist_payin_payout.therapist = therapist
    end

    if therapist_payin_payout.update(therapist_payin_payout_params)
      refresh_therapist_account(therapist_payin_payout)
      if previous_therapist && previous_time && previous_therapist != therapist_payin_payout.therapist
        Pos::UpdateTherapistAccount.call(therapist: previous_therapist, month: previous_time.month, year: previous_time.year)
      end
      render json: entry_json(therapist_payin_payout), status: :ok
    else
      render json: { errors: therapist_payin_payout.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    therapist_payin_payout = set_therapist_payin_payout
    return if therapist_payin_payout.nil?

    therapist = therapist_payin_payout.therapist
    created_at = therapist_payin_payout.created_at
    therapist_payin_payout.destroy
    Pos::UpdateTherapistAccount.call(therapist: therapist, month: created_at.month, year: created_at.year)
    render json: { message: "Therapist payin payout deleted successfully" }, status: :ok
  end

  private

  def therapist_payin_payout_params
    params.require(:therapist_payin_payout).permit(:amount, :type, :description)
  end

  def set_therapist_payin_payout
    therapist_payin_payout = TherapistPayinsPayout.find_by(id: params[:id])
    if therapist_payin_payout.nil?
      render json: { error: "Therapist payin payout not found" }, status: :not_found
      return
    end
    therapist_payin_payout
  end

  def changing_therapist?
    payload[:therapist_code].present? || payload[:th].present? || payload[:therapist_id].present?
  end

  def assigned_therapist
    code = payload[:therapist_code].presence || payload[:th].presence
    therapist = if code.present?
      Therapist.find_by(code: code)
    elsif payload[:therapist_id].present?
      Therapist.find_by(id: payload[:therapist_id])
    end

    if therapist.nil?
      render json: { error: code.present? || payload[:therapist_id].present? ? "Therapist not found" : "Therapist is required" }, status: code.present? || payload[:therapist_id].present? ? :not_found : :unprocessable_entity
      return
    end
    therapist
  end

  def payload
    params[:therapist_payin_payout].presence || ActionController::Parameters.new
  end

  def entry_json(entry)
    {
      "id" => entry.id,
      "amount" => entry.amount,
      "type" => entry.type,
      "description" => entry.description,
      "created_at" => entry.created_at&.utc&.iso8601(0)
    }
  end

  def refresh_therapist_account(record)
    return if record.therapist.nil? || record.created_at.nil?

    Pos::UpdateTherapistAccount.call(
      therapist: record.therapist,
      month: record.created_at.month,
      year: record.created_at.year
    )
  end
end
