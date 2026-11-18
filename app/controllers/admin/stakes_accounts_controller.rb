class Admin::StakesAccountsController < ApplicationController
  def index
    if invalid_period?
      render json: { error: "Month and year are invalid" }, status: :bad_request
      return
    end

    accounts = account_records

    render json: {
      "stakes_accounts" => accounts.map { |account| account_json(account) },
      "summaries" => summaries,
      "totals" => totals(accounts)
    }, status: :ok
  end

  def create
    session_record = find_session
    return if session_record.nil?

    account = StakesAccount.new(stakes_account_params.merge(session: session_record))
    if account.save
      refresh_summary(account)
      render json: account_json(account), status: :created
    else
      render json: { errors: account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    account = set_stakes_account
    return if account.nil?

    if account.settled?
      render json: { error: "Stake is settled" }, status: :unprocessable_entity
      return
    end

    previous_period = period_for(account)
    if changing_session?
      session_record = find_session
      return if session_record.nil?

      account.session = session_record
    end

    if account.update(stakes_account_params)
      refresh_period(*previous_period)
      refresh_summary(account)
      render json: account_json(account), status: :ok
    else
      render json: { errors: account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    account = set_stakes_account
    return if account.nil?

    if account.settled?
      render json: { error: "Stake is settled" }, status: :unprocessable_entity
      return
    end

    previous_period = period_for(account)
    account.destroy
    refresh_period(*previous_period)
    render json: { message: "Stakes account deleted successfully" }, status: :ok
  end

  def settle
    result = Pos::SettleStakesAccounts.call(
      ids: params[:stakes_account_ids],
      description: params[:description]
    )
    if result[:error]
      render json: { error: result[:error] }, status: result[:status]
      return
    end

    entry = result[:entry]
    render json: {
      "description" => entry.description,
      "amount" => entry.amount,
      "stakes_accounts" => result[:accounts].map { |account| account_json(account.reload) }
    }, status: :ok
  end

  private

  def account_records
    records = StakesAccount.all
    records = records.in_month(params[:month], params[:year]) if period
    records.preload(session: :client).order(created_at: :desc)
  end

  def account_json(account)
    {
      "id" => account.id,
      "amount" => account.amount,
      "settled" => account.settled,
      "session_code" => account.session&.session_code,
      "client_name" => account.session&.client&.name,
      "client_phone" => account.session&.client&.phone,
      "created_at" => account.created_at&.utc&.iso8601(0)
    }
  end

  def summaries
    if period
      [summary_json(Pos::UpdateStakesAccountSummary.call(month: params[:month], year: params[:year]))]
    else
      StakesAccountSummary.order(year: :desc, month: :desc).map { |summary| summary_json(summary) }
    end
  end

  def summary_json(summary)
    {
      "month" => summary.month,
      "year" => summary.year,
      "total_amount" => summary.total_amount,
      "amount_settled" => summary.amount_settled,
      "amount_unsettled" => summary.amount_unsettled
    }
  end

  def totals(records)
    rows = records.to_a
    {
      "total_amount" => money_sum(rows),
      "amount_settled" => money_sum(rows.select(&:settled)),
      "amount_unsettled" => money_sum(rows.reject(&:settled))
    }
  end

  def money_sum(records)
    records.sum(0.to_d) { |record| record.amount.to_d }
  end

  def stakes_account_params
    params.require(:stakes_account).permit(:amount)
  end

  def set_stakes_account
    account = StakesAccount.find_by(id: params[:id])
    if account.nil?
      render json: { error: "Stakes account not found" }, status: :not_found
      return
    end
    account
  end

  def changing_session?
    payload.key?(:ss) || payload.key?(:session_code) || payload.key?(:session_id)
  end

  def find_session
    code = payload[:ss].presence || payload[:session_code].presence
    session_record = if code.present?
      Session.find_by(session_code: code)
    elsif payload[:session_id].present?
      Session.find_by(id: payload[:session_id])
    end

    if session_record.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end
    session_record
  end

  def payload
    params[:stakes_account].presence || ActionController::Parameters.new
  end

  def refresh_summary(account)
    refresh_period(*period_for(account))
  end

  def period_for(account)
    time = account.session&.session_date || account.created_at || Time.current
    [time.month, time.year]
  end

  def refresh_period(month, year)
    Pos::UpdateStakesAccountSummary.call(month: month, year: year)
  end

  def requested_period?
    params[:month].present? || params[:year].present?
  end

  def invalid_period?
    return false unless requested_period?

    month = params[:month].to_s
    year = params[:year].to_s
    return true unless month.match?(/\A[1-9]\d?\z/) && year.match?(/\A[1-9]\d*\z/)

    !((1..12).cover?(month.to_i) && year.to_i.positive?)
  end

  def period
    return unless requested_period?

    Date.new(params[:year].to_i, params[:month].to_i, 1).in_time_zone.all_month
  end
end
