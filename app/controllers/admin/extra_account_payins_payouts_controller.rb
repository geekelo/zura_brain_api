class Admin::ExtraAccountPayinsPayoutsController < ApplicationController
  def create
    extra_account_payin_payout = ExtraAccountPayinPayout.new(extra_account_payin_payout_params)
    if extra_account_payin_payout.save
      refresh_extra_account_summary(extra_account_payin_payout)
      render json: extra_account_payin_payout, status: :created
    else
      render json: { errors: extra_account_payin_payout.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    extra_account_payin_payout = set_extra_account_payin_payout
    return if extra_account_payin_payout.nil?

    extra_account_payin_payout.update(extra_account_payin_payout_params)
    refresh_extra_account_summary(extra_account_payin_payout)
    render json: extra_account_payin_payout, status: :ok
  end

  def destroy
    extra_account_payin_payout = set_extra_account_payin_payout
    return if extra_account_payin_payout.nil?

    extra_account_payin_payout.destroy
    refresh_extra_account_summary(extra_account_payin_payout)
    render json: { message: "Extra account payin payout deleted successfully" }, status: :ok
  end

  private

  def extra_account_payin_payout_params
    params.require(:extra_account_payin_payout).permit(:session_therapist_id, :amount, :type, :description)
  end

  def set_extra_account_payin_payout
    extra_account_payin_payout = ExtraAccountPayinPayout.find_by(id: params[:extra_account_payin_payout_id])
    if extra_account_payin_payout.nil?
      render json: { error: "Extra account payin payout not found" }, status: :not_found
      return
    end
    extra_account_payin_payout
  end

  def refresh_extra_account_summary(record)
    Pos::UpdateExtraAccountSummary.call(
      month: record.created_at.month,
      year: record.created_at.year
    )
  end
end
