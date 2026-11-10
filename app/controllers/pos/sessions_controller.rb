class Pos::SessionsController < ApplicationController

"""
   st: creator therapist code
   ss: session code
"""

  def index
    sessions = Session.by_cycle
    if params[:client_id].present?
      sessions = sessions.where(client_id: params[:client_id])
    elsif params[:phone].present?
      client = Client.find_by(phone: params[:phone])
      if client.nil?
        render json: { error: "Client not found" }, status: :not_found
        return
      end
      sessions = sessions.where(client: client)
    end

    render json: sessions, status: :ok
  end

  def create
    creator_id = Pos::TherapistLookup.id_for_code(params[:st])
    if creator_id.nil?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end

    client = find_client_by_phone(params[:client_phone])
    if client.nil?
      render json: { error: "Client not found" }, status: :not_found
      return
    end

    # generate session code
    session_code = SecureRandom.hex(4).downcase

    session = Session.new(session_params.merge(session_creator_id: creator_id, client_id: client.id, session_date: Date.today, session_code: session_code))
    Pos::AssignSessionCycle.apply_to_new(session)

 
    if session.save
      Pos::AssignSessionCycle.sync_client(client)
      refresh_account_summaries(session.session_date)
      render json: session, status: :created
    else
      render json: { errors: session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    session = Session.find_by(session_code: params[:ss])
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end

    creator_id = Pos::TherapistLookup.id_for_code(params[:st])
    if creator_id.nil?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end

    if creator_id != session.session_creator_id
      render json: { error: "You are not authorized to update this session" }, status: :forbidden
      return
    end

    previous_date = session.session_date
    if session.update(session_update_params)
      refresh_account_summaries(previous_date, session.session_date)
      render json: session, status: :ok
    else
      render json: { errors: session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    session = Session.find_by(id: params[:id])
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end

    if params[:code] != ADMIN_CODE
      render json: { error: "Invalid code" }, status: :unauthorized
      return
    end

    client = session.client
    session_date = session.session_date
    session.destroy
    Pos::AssignSessionCycle.readjust(client)
    refresh_account_summaries(session_date)
    render json: { message: "Session deleted successfully" }, status: :ok
  end

  def update_transaction_id
    session = Session.find_by(session_code: params[:ss])
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end

    therapist = set_therapist(params[:th])
    if therapist != session.session_creator && params[:tc] != ADMIN_CODE
      render json: { error: "You are not authorized to update this session" }, status: :forbidden
      return
    end

    session.transaction_id = params[:transaction_id]
    session.save
  end

  def add_comment
    session = Session.find_by(session_code: params[:ss])
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end

    session.comments = normalized_comments
    if session.save
      render json: session, status: :ok
    else
      render json: { errors: session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_status
    therapist = set_therapist(params[:th])
    if therapist != session.session_creator && params[:tc] != ADMIN_CODE
      render json: { error: "You are not authorized to update this session" }, status: :forbidden
      return
    end

    session = Session.find_by(session_code: params[:ss])
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end
    
    session.status = params[:status]
    session.save
  end

  private

  def session_params
    params.require(:session).permit(:session_type, :lunez, :amount, :hands)
  end

  def session_update_params
    params.require(:session).permit(
      :session_date,
      :amount,
      :settled,
      :lunez,
      :lunez_amount,
      :hands,
      :status,
      :car_washed,
      :proof_of_payment,
      :session_type,
      :start_time,
      :end_time
    )
  end

  def normalized_comments
    Array(params[:comments]).map do |entry|
      permitted = entry.permit(:name, :comment, :date_time)
      {
        "name" => permitted[:name].to_s,
        "comment" => permitted[:comment].to_s,
        "date_time" => permitted[:date_time].presence || Time.current.iso8601
      }
    end
  end

  def refresh_account_summaries(*dates)
    dates.compact.map { |date| [date.month, date.year] }.uniq.each do |month, year|
      Pos::UpdateLunezAccount.call(month: month, year: year)
      Pos::UpdateMainAccount.call(month: month, year: year)
    end
  end

  def find_client_by_phone(phone)
    client = Client.find_by(phone: phone)
    if client.nil?
      render json: { error: "Client not found" }, status: :not_found
      return
    end
    client
  end

  def set_th

end
