class Pos::ClientsController < ApplicationController

  def index
    clients = Client.search(params[:search]).to_a
    counts = session_counts_by_client(clients)
    render json: clients.map { |client| client_json(client, counts[client.id]) }, status: :ok
  end

  def show
    client = Client.find_by(params[:phone])
    if client.nil?
      render json: { error: "Client not found" }, status: :not_found
      return
    end
    render json: client_json(client, session_counts_by_client([client])[client.id]), status: :ok
  end

  def create
    # get the therapist who is creating client
    created_by_name = set_therapist
    return if created_by_name.nil?

    client = Client.new(client_params.merge(created_by: created_by_name))
    if client.save
        render json: client_attributes(client), status: :created
    else
        render json: { errors: client.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    client = find_client_by_phone
    return if client.nil?
    unless admin_authorized?
      render json: { error: "Not authorized" }, status: :unauthorized
      return
    end

    if client.update(client_params)
      render json: client_attributes(client), status: :ok
    else
      render json: { errors: client.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_preferences
    client = find_client_by_phone
    return if client.nil?

    if client.update(client_preferences: params[:client_preferences])
      render json: client_attributes(client), status: :ok
    else
      render json: { errors: client.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    client = find_client_by_phone

    code = params[:code]
    if AdminCode.matches?(code)
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

  def session_counts_by_client(clients)
    grouped = Session.where(client_id: clients.map(&:id)).group(:client_id, :status).count
    counts = Hash.new { |by_client, client_id| by_client[client_id] = Hash.new(0) }
    grouped.each do |(client_id, status), total|
      counts[client_id][status] = total
      counts[client_id][:total] += total
    end
    counts
  end

  def client_attributes(client)
    client.as_json.except("id", :id)
  end

  def client_json(client, counts)
    counts ||= {}
    client_attributes(client).merge(
      "total_sessions" => counts[:total].to_i,
      "completed_sessions" => counts["completed"].to_i,
      "pending_sessions" => counts["pending"].to_i,
      "disputed_sessions" => counts["disputed"].to_i,
      "ongoing_sessions" => counts["started"].to_i
    )
  end
end
