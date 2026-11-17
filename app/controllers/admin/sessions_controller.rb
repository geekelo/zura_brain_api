class Admin::SessionsController < ApplicationController

"""
   st: creator therapist code
   ss: session code
"""

  def index
    sessions = Session.by_cycle.includes(:client, :session_creator, :payment_methods, session_therapists: :therapist)
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
    render json: sessions.map { |session_record| session_json(session_record) }, status: :ok
  end

  def create
    creator_id = Pos::TherapistLookup.id_for_code(params[:st])
    if creator_id.nil?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end

    client = find_client_by_phone(params[:client_phone])
    return if client.nil?

    # generate session code
    session_code = SecureRandom.hex(4).downcase

    session = Session.new(session_params.merge(session_creator_id: creator_id, client_id: client.id, session_date: Date.today, session_code: session_code))
    Pos::AssignSessionCycle.apply_to_new(session)

    begin
      ActiveRecord::Base.transaction do
        session.save!
        upsert_client_support!(session)
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      return
    end

    Pos::AssignSessionCycle.sync_client(client) unless session.off_cycle
    refresh_account_summaries(session.session_date)
    render json: session_json(session), status: :created
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
    begin
      ActiveRecord::Base.transaction do
        session.update!(session_update_params)
        upsert_client_support!(session)
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      return
    end

    refresh_account_summaries(previous_date, session.session_date)
    render json: session_json(session), status: :ok
  end

  def destroy
    session = Session.find_by(id: params[:id])
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end

    if !AdminCode.matches?(params[:code])
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

    return unless authorized?(session)

    session.transaction_id = params[:transaction_id]
    if session.save
      render json: session_json(session), status: :ok
    else
      render json: { errors: session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def verify_payment
    session = Session.find_by(session_code: params[:ss])
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end

    unless admin_authorized?
      render json: { error: "Not authorized" }, status: :unauthorized
      return
    end

    session.session_history = session.session_history.to_h.merge("payment_verified" => true)
    if session.save
      render json: session_json(session), status: :ok
    else
      render json: { errors: session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def add_comment
    session = Session.find_by(session_code: params[:ss])
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end

    session.comments = normalized_comments
    if session.save
      render json: session_json(session), status: :ok
    else
      render json: { errors: session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def resolve_comment
    session = Session.find_by(session_code: params[:ss])
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end

    comments = Array(session.comments).map { |entry| entry.to_h.stringify_keys }
    index = params[:index].to_i
    unless params[:index].to_s.match?(/\A\d+\z/) && comments[index]
      render json: { error: "Comment not found" }, status: :not_found
      return
    end

    comments[index]["resolved"] = ActiveModel::Type::Boolean.new.cast(params[:resolved])
    session.comments = comments

    if session.save
      render json: session_json(session), status: :ok
    else
      render json: { errors: session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_status
    session = Session.find_by(session_code: params[:ss])
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end

    if %w[completed disputed].include?(params[:status].to_s)
      unless admin_authorized?
        render json: { error: "Not authorized" }, status: :unauthorized
        return
      end
    else
      return unless authorized?(session)
    end

    session.status = params[:status]
    history = (session.session_history || {}).to_h.stringify_keys
    history["started"] = true if session.start_time.present?
    history["ended"] = true if session.end_time.present?
    history["completed"] = true if session.status == "completed"
    history["completed"] = false if session.status == "disputed"
    session.session_history = history

    if session.save
      render json: session_json(session), status: :ok
    else
      render json: { errors: session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def start_end_session
    session = Session.find_by(session_code: params[:ss])
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end
    
    session.start_time = params[:start_time] if params.key?(:start_time)
    session.end_time = params[:end_time] if params.key?(:end_time)

    if session.start_time.present? && session.end_time.present?
      session.duration = (session.end_time - session.start_time).to_i
      session.status = "ended"
    elsif session.start_time.present?
      session.status = "started"
    end

    history = (session.session_history || {}).to_h.stringify_keys
    history["started"] = true if session.start_time.present?
    history["ended"] = true if session.end_time.present?
    session.session_history = history

    if session.save
      render json: session_json(session), status: :ok
    else
      render json: { errors: session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def session_json(session_record)
    loaded = Session.includes(:client, :session_creator, :payment_methods, :client_supports, session_therapists: :therapist).find(session_record.id)
    loaded.as_json(
      include: {
        client: { only: [:name, :phone] },
        session_creator: { only: [:work_name] }
      }
    ).merge(
      "session_therapists" => loaded.session_therapists.map { |link|
        {
          "name" => link.therapist&.work_name,
          "role" => link.role,
          "tip_amount" => link.tip_amount,
          "tip_balance" => link.tip_balance
        }
      },
      "client_support" => client_support_json(loaded)
    )
  end

  def client_support_json(session_record)
    support = session_record.client_supports.max_by { |row| [row.created_at, row.id] }
    return nil if support.nil?

    {
      "description" => support.description,
      "notes" => support.notes,
      "amount" => support.amount,
      "type" => support.type
    }
  end

  def upsert_client_support!(session)
    return unless client_support_param?

    support = session.client_supports.order(created_at: :desc, id: :desc).first || session.client_supports.build
    support.update!(client_support_attributes)
  end

  def client_support_param?
    client_support_source.present?
  end

  def client_support_source
    source = params[:client_support]
    if source.blank? && params[:session].respond_to?(:key?) && params[:session].key?(:client_support)
      source = params[:session][:client_support]
    end
    source
  end

  def client_support_attributes
    client_support_source.permit(:description, :notes, :amount, :type)
  end

  def session_params
    params.require(:session).permit(:session_type, :massage_type, :lunez, :amount, :hands, :off_cycle)
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
      :massage_type,
      :start_time,
      :end_time
    )
  end

  def normalized_comments
    Array(params[:comments]).map do |entry|
      permitted = entry.permit(:name, :comment, :date_time, :resolved)
      {
        "name" => permitted[:name].to_s,
        "comment" => permitted[:comment].to_s,
        "date_time" => permitted[:date_time].presence || Time.current.iso8601,
        "resolved" => ActiveModel::Type::Boolean.new.cast(permitted[:resolved]) || false
      }
    end
  end

  def refresh_account_summaries(*dates)
    dates.compact.map { |date| [date.month, date.year] }.uniq.each do |month, year|
      Pos::UpdateLunezAccount.call(month: month, year: year)
      Pos::UpdateMainAccount.call(month: month, year: year)
      Pos::UpdateClientSupportSummary.call(month: month, year: year)
      Pos::UpdateStakesAccountSummary.call(month: month, year: year)
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

  def set_therapist(code)
    therapist = Therapist.find_by(code: code)
    if therapist.nil?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end
    therapist
  end

end
