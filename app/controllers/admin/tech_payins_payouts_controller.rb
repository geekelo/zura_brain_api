class Admin::TechPayinsPayoutsController < ApplicationController
  def create
    tech_payin_payout = TechPayinsPayout.new(tech_payin_payout_params)
    if tech_payin_payout.save
      refresh_tech_account_summary(tech_payin_payout)
      render json: tech_payin_payout, status: :created
    else
      render json: { errors: tech_payin_payout.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    tech_payin_payout = set_tech_payin_payout
    return if tech_payin_payout.nil?

    if tech_payin_payout.update(tech_payin_payout_params)
      refresh_tech_account_summary(tech_payin_payout)
      render json: tech_payin_payout, status: :ok
    else
      render json: { errors: tech_payin_payout.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    tech_payin_payout = set_tech_payin_payout
    return if tech_payin_payout.nil?

    created_at = tech_payin_payout.created_at
    tech_payin_payout.destroy
    Pos::UpdateTechAccountSummary.call(month: created_at.month, year: created_at.year)
    render json: { message: "Tech payin payout deleted successfully" }, status: :ok
  end

  private

  def tech_payin_payout_params
    params.require(:tech_payin_payout).permit(:extra_account_id, :amount, :type, :description)
  end

  def set_tech_payin_payout
    tech_payin_payout = TechPayinsPayout.find_by(id: params[:tech_account_id])
    if tech_payin_payout.nil?
      render json: { error: "Tech payin payout not found" }, status: :not_found
      return
    end
    tech_payin_payout
  end

  def refresh_tech_account_summary(record)
    Pos::UpdateTechAccountSummary.call(month: record.created_at.month, year: record.created_at.year)
  end
end
