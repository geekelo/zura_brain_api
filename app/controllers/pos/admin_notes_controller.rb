class Pos::AdminNotesController < ApplicationController
  before_action :set_admin_note, only: [:show, :update, :destroy]

  ### ss: session code, st: therapist code, an: admin note id, thr: staff id
  
  def index
    @admin_notes = AdminNote.all
  end

  def create
    therapist = set_therapist(params[:st])
    session = set_session(params[:ss])
    staff = params[:thr]
    admin_note = AdminNote.new(admin_note_params.merge(creator_id: therapist.id, session_id: session.id, therapist_id: staff))
    if admin_note.save
      render json: admin_note, status: :created
    else
      render json: { errors: admin_note.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    therapist = set_therapist(params[:st])
    admin_note = AdminNote.find_by(id: params[:admin_note_id])
    if admin_note.nil?
      render json: { error: "Admin note not found" }, status: :not_found
      return
    end
    if admin_note.creator_id != therapist.id
      render json: { error: "Not authorized to update this note" }, status: :unauthorized
      return
    end
    if admin_note.update(admin_note_params)
      render json: admin_note, status: :ok
    else
      render json: { errors: admin_note.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    therapist = set_therapist(params[:st])
    admin_note = AdminNote.find_by(id: params[:an])
    if admin_note.nil?
      render json: { error: "Admin note not found" }, status: :not_found
      return
    end
    if admin_note.creator_id != therapist.id
      render json: { error: "Not authorized to delete this note" }, status: :unauthorized
      return
    end
    admin_note.destroy
    render json: { message: "Admin note deleted successfully" }, status: :ok
    else
      render json: { errors: admin_note.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_therapist(st)
    therapist = Pos::TherapistLookup.id_for_code(st)
    if therapist.nil?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end
    therapist
  end
  def admin_note_params
    params.require(:admin_note).permit(:note)
  end

  def set_session(ss)
    session = Session.find_by(code: ss)
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end
    session
  end

  def set_admin_note
    admin_note = AdminNote.find(params[:id])
  end
end
