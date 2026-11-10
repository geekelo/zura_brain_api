class Pos::PaymentMethodsController < ApplicationController
  def create
    payment_method = PaymentMethod.new(payment_method_params)
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

  def destroy
    payment_method = set_payment_method
    return if payment_method.nil?

    payment_method.destroy
    render json: { message: "Payment method deleted successfully" }, status: :ok
  end

  private

  def payment_method_params
    params.require(:payment_method).permit(:session_id, :type, :amount, :status)
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
