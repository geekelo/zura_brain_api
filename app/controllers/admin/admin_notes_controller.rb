class Admin::AdminNotesController < ApplicationController
  ### st: creator therapist code, phone: client, ss: session code, th: therapist the note is about, an: admin note id

  def index
    notes = AdminNote.includes(:client, :session, :therapist, :creator).order(created_at: :desc)
    render json: notes.map { |note| note_json(note) }, status: :ok
  end

  def create
    creator = note_creator
    return if performed?

    targets = note_targets
    return if targets.nil?
    if targets.empty?
      render json: { error: "Client, session, or therapist is required" }, status: :unprocessable_entity
      return
    end

    admin_note = AdminNote.new(admin_note_params.merge(targets.merge(creator_id: creator&.id)))
    if admin_note.save
      render json: note_json(admin_note), status: :created
    else
      render json: { errors: admin_note.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    admin_note = AdminNote.find_by(id: params[:admin_note_id])
    if admin_note.nil?
      render json: { error: "Admin note not found" }, status: :not_found
      return
    end
    return unless can_change?(admin_note)

    if admin_note.update(admin_note_params)
      render json: note_json(admin_note), status: :ok
    else
      render json: { errors: admin_note.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    therapist = set_therapist(params[:st])
    return if therapist.nil?

    admin_note = AdminNote.find_by(id: params[:an])
    if admin_note.nil?
      render json: { error: "Admin note not found" }, status: :not_found
      return
    end
    if admin_note.creator_id != therapist.id && !admin_authorized?
      render json: { error: "Not authorized to delete this note" }, status: :unauthorized
      return
    end
    if admin_note.destroy
      render json: { message: "Admin note deleted successfully" }, status: :ok
    else
      render json: { errors: admin_note.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def note_creator
    if params[:st].present?
      set_therapist(params[:st])
    elsif admin_authorized?
      nil
    else
      render json: { error: "Not authorized" }, status: :unauthorized
      nil
    end
  end

  def can_change?(admin_note)
    return true if admin_authorized?

    therapist = set_therapist(params[:st])
    return false if therapist.nil?
    return true if admin_note.creator_id == therapist.id

    render json: { error: "Not authorized to update this note" }, status: :unauthorized
    false
  end

  def set_therapist(st)
    therapist = Therapist.find_by(code: st)
    if therapist.nil?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end
    therapist
  end

  def admin_note_params
    params.require(:admin_note).permit(:body, :status)
  end

  def note_json(note)
    {
      "id" => note.id,
      "body" => note.body,
      "status" => note.status,
      "created_at" => note.created_at&.utc&.iso8601(0),
      "client_id" => note.client_id,
      "client_name" => note.client&.name,
      "client_phone" => note.client&.phone,
      "session_id" => note.session_id,
      "session_code" => note.session&.session_code,
      "therapist_id" => note.therapist_id,
      "therapist_name" => note.therapist&.work_name,
      "therapist_code" => note.therapist&.code
    }
  end

  # phone: client, ss: session code, th: therapist the note is about.
  # Returns nil after rendering when a supplied target cannot be found.
  def note_targets
    targets = {}

    if params[:phone].present?
      client = Client.find_by(phone: params[:phone])
      if client.nil?
        render json: { error: "Client not found" }, status: :not_found
        return
      end
      targets[:client_id] = client.id
    end

    if params[:ss].present?
      session_record = Session.find_by(session_code: params[:ss])
      if session_record.nil?
        render json: { error: "Session not found" }, status: :not_found
        return
      end
      targets[:session_id] = session_record.id
    end

    if params[:th].present?
      subject = Therapist.find_by(code: params[:th])
      if subject.nil?
        render json: { error: "Therapist not found" }, status: :not_found
        return
      end
      targets[:therapist_id] = subject.id
    end

    targets
  end
end
