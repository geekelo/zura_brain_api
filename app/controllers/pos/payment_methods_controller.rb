class Pos::PaymentMethodsController < ApplicationController
  def create
    session = set_session
    return if session.nil?

    payment_method = PaymentMethod.new(payment_method_params.merge(session_id: session.id))
    if payment_method.save
      render json: payment_method, status: :created
    else
      render json: { errors: payment_method.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    payment_method = set_payment_method
    return if payment_method.nil?

    if payment_method.update(payment_method_params)
      render json: payment_method, status: :ok
    else
      render json: { errors: payment_method.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def upload_receipt
    payment_method = set_payment_method
    return if payment_method.nil?

    file = params[:receipt]
    if file.blank?
      render json: { error: "Receipt file is required" }, status: :bad_request
      return
    end

    uploaded = Pos::ImgbbUpload.call(file, name: receipt_name(payment_method))
    uploaded_at = Time.current
    receipts = payment_method.payment_url.to_a
    receipt = {
      "view_url" => uploaded[:view_url],
      "delete_url" => uploaded[:delete_url],
      "uploaded_at" => uploaded_at.iso8601,
      "time" => uploaded[:time].to_s
    }
    index = params[:index].presence&.to_i
    if index && receipts[index]
      receipts[index] = receipt
    else
      receipts << receipt
    end
    payment_method.payment_url = receipts
    payment_method.receipt_uploaded_at = uploaded_at

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

    payment_method.destroy
    render json: { message: "Payment method deleted successfully" }, status: :ok
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

  def receipt_name(payment_method)
    params[:name].presence || "receipt-#{payment_method.id}-#{payment_method.payment_url.to_a.size + 1}"
  end

  def set_payment_method
    payment_method = PaymentMethod.find_by(id: params[:id])
    if payment_method.nil?
      render json: { error: "Payment method not found" }, status: :not_found
      return
    end
    payment_method
  end
end
