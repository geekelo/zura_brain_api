class Admin::ExtraAccountSummariesController < ApplicationController
  def create
    month = params[:month].to_i
    year = params[:year].to_i
    unless (1..12).cover?(month) && year.positive?
      render json: { error: "Month and year are invalid" }, status: :bad_request
      return
    end

    summary = Pos::UpdateExtraAccountSummary.call(month: month, year: year)
    render json: summary, status: :ok
  end
end
