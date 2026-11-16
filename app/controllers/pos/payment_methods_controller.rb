class Pos::PaymentMethodsController < ApplicationController
  def create
    session = set_session
    return if session.nil?
    return unless authorized?(session)

    payment_method = PaymentMethod.new(payment_method_params.merge(session_id: session.id))
    attach_receipt(payment_method) if params[:receipt].present?
    if payment_method.save
      render json: payment_method, status: :created
    else
      render json: { errors: payment_method.errors.full_messages }, status: :unprocessable_entity
    end
  rescue Pos::ImgbbUpload::Error, KeyError => error
    render json: { error: error.message }, status: :bad_gateway
  end

  def update
    payment_method = set_payment_method
    return if payment_method.nil?
    return unless authorized?(payment_method.session)

    payment_method.assign_attributes(payment_method_params) if params[:payment_method].present?
    attach_receipt(payment_method) if params[:receipt].present?

    if payment_method.save
      render json: payment_method, status: :ok
    else
      render json: { errors: payment_method.errors.full_messages }, status: :unprocessable_entity
    end
  rescue Pos::ImgbbUpload::Error, KeyError => error
    render json: { error: error.message }, status: :bad_gateway
  end

  def upload_receipt
    payment_method = set_payment_method
    return if payment_method.nil?
    return unless authorized?(payment_method.session)

    file = params[:receipt]
    if file.blank?
      render json: { error: "Receipt file is required" }, status: :bad_request
      return
    end

    attach_receipt(payment_method)

    if payment_method.save
      render json: payment_method, status: :ok
    else
      render json: { errors: payment_method.errors.full_messages }, status: :unprocessable_entity
    end
  rescue Pos::ImgbbUpload::Error, KeyError => error
    render json: { error: error.message }, status: :bad_gateway
  end

  def destroy
    payment_method = set_payment_method
    return if payment_method.nil?
    # Admin code, or the session creator's therapist code.
    return unless authorized?(payment_method.session)

    # Remove the row when the caller is an admin, or when there is no receipt.
    # A non-admin can only fully delete a payment method whose payment_url is [].
    if admin_delete? || payment_url_empty?(payment_method)
      del_urls = delete_urls(payment_method)
      payment_method.destroy
      body = { message: "Payment method deleted successfully" }
      # Admin deletes return the ImgBB delete URL so the image can be removed in a browser.
      if admin_delete?
        body[:del_url] = del_urls.first
        body[:del_urls] = del_urls
      end
      render json: body, status: :ok
    else
      # A receipt is stored and the caller is not an admin: keep the row and hide it.
      payment_method.update!(deleted_at: Time.current)
      render json: { message: "Payment method deleted successfully" }, status: :ok
    end
  end

  private

  def payment_method_params
    params.require(:payment_method).permit(:source, :type, :amount, :status)
  end

  def set_session
    session = Session.find_by(session_code: params[:session_code])
    if session.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end
    session
  end

  def attach_receipt(payment_method)
    uploaded = Pos::ImgbbUpload.call(params[:receipt], name: receipt_name(payment_method))
    payment_method.payment_url = [
      {
        "img_url" => uploaded[:img_url],
        "del_url" => uploaded[:del_url],
        "date_time" => uploaded[:date_time]
      }
    ]
    payment_method.receipt_uploaded_at = Time.current
  end

  def receipt_name(payment_method)
    session_record = payment_method.session
    client = session_record.client
    [client.name, client.phone, session_record.cycle, session_record.cycle_length].compact.join(" ")
  end

  def payment_url_empty?(payment_method)
    Array(payment_method.payment_url).empty?
  end

  def admin_delete?
    [params[:code], params[:th], params[:tc]].any? { |code| AdminCode.matches?(code) }
  end

  def delete_urls(payment_method)
    Array(payment_method.payment_url).filter_map do |receipt|
      next unless receipt.is_a?(Hash)

      receipt["del_url"] || receipt[:del_url]
    end
  end

  def set_payment_method
    payment_method = PaymentMethod.active.find_by(id: params[:id])
    if payment_method.nil?
      render json: { error: "Payment method not found" }, status: :not_found
      return
    end
    payment_method
  end
end
