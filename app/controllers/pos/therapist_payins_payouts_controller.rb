class Pos::TherapistPayinsPayoutsController < ApplicationController
  def create
    therapist_payin_payout = TherapistPayinsPayout.new(therapist_payin_payout_params)
    if therapist_payin_payout.save
      refresh_therapist_account(therapist_payin_payout)
      render json: therapist_payin_payout, status: :created
    else
      render json: { errors: therapist_payin_payout.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    therapist_payin_payout = TherapistPayinsPayout.find_by(id: params[:id])
    if therapist_payin_payout.nil?
      render json: { error: "Therapist payin payout not found" }, status: :not_found
      return
    end
    therapist_payin_payout.update(therapist_payin_payout_params)
    refresh_therapist_account(therapist_payin_payout)
    render json: therapist_payin_payout, status: :ok
  end

  def destroy
    therapist_payin_payout = TherapistPayinsPayout.find_by(id: params[:id])
    if therapist_payin_payout.nil?
      render json: { error: "Therapist payin payout not found" }, status: :not_found
      return
    end
    therapist_payin_payout.destroy
    refresh_therapist_account(therapist_payin_payout)
    render json: { message: "Therapist payin payout deleted successfully" }, status: :ok
  end

  private

  def therapist_payin_payout_params
    params.require(:therapist_payin_payout).permit(:therapist_id, :amount, :type)
  end

  def refresh_therapist_account(record)
    Pos::UpdateTherapistAccount.call(
      therapist: record.therapist,
      month: record.created_at.month,
      year: record.created_at.year
    )
  end
end
