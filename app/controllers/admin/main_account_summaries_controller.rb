class Admin::MainAccountSummariesController < ApplicationController
  def create
    month = params[:month].to_i
    year = params[:year].to_i
    unless (1..12).cover?(month) && year.positive?
      render json: { error: "Month and year are invalid" }, status: :bad_request
      return
    end

    account = Pos::UpdateMainAccount.call(month: month, year: year)
    render json: account, status: :ok
  end
end
