class Admin::SessionActivitiesController < ApplicationController

    ### ss: session code, st: therapist code

  def create
    therapist = set_therapist(params[:st])
    session = Session.find_by(session_code: params[:ss])
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end

    session_activity_params = activity_params.merge(session_id: session.id, therapist_id: therapist.id)
    session_activity = SessionActivity.new(session_activity_params)
    if session_activity.save
      render json: session_activity, status: :created
    else
      render json: { errors: session_activity.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    session = set_session
    therapist = set_therapist(params[:st])
    session_activity = SessionActivity.find_by(id: params[:session_activity_id])
    if session_activity.nil?
      render json: { error: "Session activity not found" }, status: :not_found
      return
    end
    if session_activity.session_id != session.id || session_activity.therapist_id != therapist.id
      render json: { error: "Not authorized to update this activity" }, status: :unauthorized
      return
    end
    if session_activity.update(activity_params)
      render json: session_activity, status: :ok
    else
      render json: { errors: session_activity.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    session = set_session
    therapist = set_therapist(params[:st])

    # get session activity id from params
    session_activity = SessionActivity.find_by(id: params[:session_activity_id])
    if session_activity.nil?
      render json: { error: "Session activity not found" }, status: :not_found
      return
    end

    if session_activity.session_id != session.id || session_activity.therapist_id != therapist.id
      render json: { error: "Not authorized to delete this activity" }, status: :unauthorized
      return
    end

    if session_activity.destroy
      render json: { message: "Session activity deleted successfully" }, status: :ok
    else
      render json: { errors: session_activity.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_session
    session = Session.find_by(session_code: params[:ss])
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end
    session
  end

  def set_therapist
    therapist = Pos::TherapistLookup.id_for_code(code)
    if therapist.nil?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end
    therapist
  end

  def activity_params
    params.require(:activity).permit(:action)
  end
end
