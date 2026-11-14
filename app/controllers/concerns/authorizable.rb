module Authorizable
  extend ActiveSupport::Concern

  def authorized?(session_record)
    return true if admin_authorized? || session_creator?(session_record)

    render json: { error: "Not authorized" }, status: :unauthorized
    false
  end

  private

  def admin_authorized?
    AdminCode.matches?(params[:code]) || AdminCode.matches?(params[:tc])
  end

  def session_creator?(session_record)
    creator_code = session_record&.session_creator&.code
    return false if creator_code.blank?

    [params[:code], params[:th]].any? { |code| code.present? && code == creator_code }
  end
end
