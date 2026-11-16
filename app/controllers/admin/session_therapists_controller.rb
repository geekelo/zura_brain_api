class Admin::SessionTherapistsController < ApplicationController
  def create
    
    therapist = Therapist.find_by(work_name: params[:name])
    if therapist.nil?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end
    session = Session.find_by(session_code: params[:ss])
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end

    return unless authorized?(session)

    session_therapist = SessionTherapist.new(
      session_therapist_params.merge(therapist_id: therapist.id, session_id: session.id)
    )
    if session_therapist.save
      render json: session_therapist, status: :created
    else
      render json: { errors: session_therapist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    session = Session.find_by(session_code: params[:ss])
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end
    return unless authorized?(session)

    therapist = Therapist.find_by(work_name: params[:name])
    if therapist.nil?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end

    session_therapist = SessionTherapist.find_by(session_id: session.id, therapist_id: therapist.id)
    if session_therapist.nil?
      render json: { error: "Session therapist not found" }, status: :not_found
      return
    end

    if session_therapist.tip_amount.to_d > 0
      render json: { error: "Session therapist has tip amount" }, status: :unprocessable_entity
      return
    end

    if session_therapist.destroy
      render json: { message: "Session therapist deleted successfully" }, status: :ok
    else
      render json: { errors: session_therapist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def tip
    admin_code = params[:admin_code].presence || params[:tc]
    if admin_code.nil?
      render json: { error: "Admin code is required" }, status: :bad_request
      return
    end
    unless AdminCode.matches?(admin_code)
      render json: { error: "Not authorized to tip" }, status: :unauthorized
      return
    end

    session_record = Session.find_by(session_code: params[:ss])
    if session_record.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end

    therapist = Therapist.find_by(work_name: params[:name])
    if therapist.nil?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end

    session_therapist = SessionTherapist.find_by(session_id: session_record.id, therapist_id: therapist.id)
    if session_therapist.nil?
      render json: { error: "Session therapist not found" }, status: :not_found
      return
    end

    tip_amount = decimal_tip_amount
    if tip_amount.nil? || tip_amount <= 0
      render json: { error: "Tip amount is invalid" }, status: :bad_request
      return
    end

    result = Pos::ApplyTip.call(session_therapist: session_therapist, tip_amount: tip_amount)
    render json: {
      name: therapist.work_name,
      tip_amount: result[:session_therapist].tip_amount,
      tip_balance: result[:session_therapist].tip_balance,
      extra_account_amount: result[:extra_account].amount,
      tech_account_amount: result[:tech_account].amount
    }, status: :ok
  end

  private

  def decimal_tip_amount
    BigDecimal(params[:tip_amount].to_s)
  rescue ArgumentError
    nil
  end
  
  def session_therapist_params
    params.require(:session_therapist).permit(:session_id, :therapist_id, :role, :tip_amount, :tip_balance, :points, :feedback)
  end
end

