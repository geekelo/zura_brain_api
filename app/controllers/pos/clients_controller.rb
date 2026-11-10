class Pos::ClientsController < ApplicationController

  def index
    clients = Client.search(params[:search])
    render json: clients, status: :ok
  end

  def show
    client = Client.find(params[:id])
    render json: client, status: :ok
  end

  def create
    # get the therapist who is creating client
    created_by_name = set_therapist
    return if created_by_name.nil?

    client = Client.new(client_params.merge(created_by: created_by_name))
    if client.save
        render json: client, status: :created
    else
        render json: { errors: client.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    client = find_client_by_phone
    if client.update(client_params)
      render json: client, status: :ok
    else
      render json: { errors: client.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    client = find_client_by_phone

    code = params[:code]
    if code == ADMIN_CODE
      client.destroy
      render json: { message: "Client deleted successfully" }, status: :ok
    else
      render json: { error: "Invalid code" }, status: :unauthorized
    end
  end

  private

  def set_therapist
    code = params[:code]
    therapist = Pos::TherapistLookup.name_for_code(code)
    if therapist.nil?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end
    therapist
  end

  def find_client_by_phone
    client = Client.find_by(phone: params[:phone])
    if client.nil?
      render json: { error: "Client not found" }, status: :not_found
      return
    end
    client
  end

  def client_params
    params.require(:client).permit(:name, :phone, :cycle, :cycle_length, :sex, :adult, other_phones: [])
  end
end
