class Pos::TherapistsController < ApplicationController
  def index
    therapists = Therapist.all
    therapists = therapists.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params.key?(:active)
    # don't include therapist code in the response
    therapists = therapists.select(:work_name, :active)
    render json: therapists.order(:work_name), status: :ok
  end

  def show
    therapist = find_therapist
    return if therapist.nil?

    render json: therapist, status: :ok
  end

  def create
    return unless admin?

    therapist = Therapist.new(therapist_params)
    if therapist.save
      render json: therapist, status: :created
    else
      render json: { errors: therapist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_status
    return unless admin?

    therapist = find_therapist
    return if therapist.nil?

    if therapist.update(active: ActiveModel::Type::Boolean.new.cast(params[:active]))
      render json: therapist, status: :ok
    else
      render json: { errors: therapist.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def find_therapist
    therapist = Therapist.find_by(code: params[:code])
    if therapist.nil?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end
    therapist
  end

  def admin?
    return true if AdminCode.matches?(params[:tc])

    render json: { error: "Not authorized" }, status: :unauthorized
    false
  end

  def therapist_params
    params.require(:therapist).permit(:work_name, :code, :avatar, :url, :active)
  end
end
