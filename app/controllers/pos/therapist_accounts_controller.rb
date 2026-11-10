class Pos::TherapistAccountsController < ApplicationController
  def create
    therapist = set_therapist

    month = params[:month].to_i
    year = params[:year].to_i
    unless (1..12).cover?(month) && year.positive?
      render json: { error: "Month and year are invalid" }, status: :bad_request
      return
    end

    account = Pos::UpdateTherapistAccount.call(therapist: therapist, month: month, year: year)
    render json: account, status: :ok
  end

  private

  def set_therapist
    therapist = Therapist.find_by(id: params[:therapist_id])
    if therapist.nil?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end
    therapist
  end
end
