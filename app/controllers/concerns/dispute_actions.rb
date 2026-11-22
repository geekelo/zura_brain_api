module DisputeActions
  extend ActiveSupport::Concern

  def index
    disputes = Dispute.includes(:assigned_staff, session: :client).order(created_at: :desc, id: :desc)
    render json: disputes.map(&:as_api_json), status: :ok
  end

  def create
    return unless admin_dispute?

    session_record = Session.find_by(session_code: session_code_param)
    if session_record.nil?
      render json: { error: "Session not found" }, status: :not_found
      return
    end

    staff = therapists_from(assigned_staff_codes)
    return if performed?

    dispute = session_record.disputes.build(description: description_param)
    unless dispute.save
      render json: { errors: dispute.errors.full_messages }, status: :unprocessable_entity
      return
    end

    dispute.assigned_staff = staff if staff
    mark_session_disputed(session_record)
    render json: dispute.reload.as_api_json, status: :created
  end

  def update
    dispute = set_dispute
    return if dispute.nil?
    return unless admin_dispute?

    staff = therapists_from(assigned_staff_codes) if assigned_staff_provided?
    return if performed?

    dispute.description = description_param if description_param.present?
    unless dispute.save
      render json: { errors: dispute.errors.full_messages }, status: :unprocessable_entity
      return
    end

    dispute.assigned_staff = staff if staff
    render json: dispute.reload.as_api_json, status: :ok
  end

  def resolve
    dispute = set_dispute
    return if dispute.nil?
    return unless admin_dispute?

    urls = resolution_urls
    Array(params[:images]).each do |file|
      next unless file.respond_to?(:tempfile)

      urls << upload_dispute_image(file, "dispute-resolution")
      return if performed?
    end

    dispute.resolved = true
    dispute.resolution = { "text" => resolution_text, "image_urls" => urls.uniq }
    if dispute.save
      render json: dispute.as_api_json, status: :ok
    else
      render json: { errors: dispute.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def add_thread
    dispute = set_dispute
    return if dispute.nil?

    therapist = Therapist.find_by(code: params[:th].to_s.strip)
    if therapist.nil?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end

    name = thread_name
    unless name.present? && name.casecmp?(therapist.work_name.to_s.strip)
      render json: { error: "Name does not match therapist" }, status: :unprocessable_entity
      return
    end

    text = thread_text
    if text.blank?
      render json: { error: "Text is required" }, status: :unprocessable_entity
      return
    end

    image_url = thread_image_url
    if params[:image].respond_to?(:tempfile)
      image_url = upload_dispute_image(params[:image], "dispute-thread")
      return if performed?
    end

    entries = Array(dispute.thread).map { |entry| Dispute.thread_entry(entry) }
    entries << {
      "name" => therapist.work_name,
      "text" => text,
      "datetime" => Time.current.utc.iso8601(0),
      "image_url" => image_url.to_s
    }
    dispute.thread = entries
    if dispute.save
      render json: dispute.as_api_json, status: :ok
    else
      render json: { errors: dispute.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_thread
    dispute = set_dispute
    return if dispute.nil?
    return unless admin_dispute?

    entries = Array(dispute.thread).map { |entry| Dispute.thread_entry(entry) }
    index = thread_index
    unless index && entries[index]
      render json: { error: "Thread not found" }, status: :not_found
      return
    end

    entry = entries[index]
    entry["text"] = thread_text if thread_text.present?
    entry["name"] = thread_name if thread_name.present?
    entry["image_url"] = thread_image_url if thread_image_url.present?
    if params[:image].respond_to?(:tempfile)
      entry["image_url"] = upload_dispute_image(params[:image], "dispute-thread")
      return if performed?
    end
    entries[index] = entry
    dispute.thread = entries
    if dispute.save
      render json: dispute.as_api_json, status: :ok
    else
      render json: { errors: dispute.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy_thread
    dispute = set_dispute
    return if dispute.nil?
    return unless admin_dispute?

    entries = Array(dispute.thread).map { |entry| Dispute.thread_entry(entry) }
    index = thread_index
    unless index && entries[index]
      render json: { error: "Thread not found" }, status: :not_found
      return
    end

    entries.delete_at(index)
    dispute.thread = entries
    dispute.save!
    render json: dispute.as_api_json, status: :ok
  end

  private

  def set_dispute
    dispute = Dispute.includes(:assigned_staff, session: :client).find_by(id: params[:id])
    if dispute.nil?
      render json: { error: "Dispute not found" }, status: :not_found
      return
    end
    dispute
  end

  def admin_dispute?
    return true if AdminCode.matches?(params[:code]) || AdminCode.matches?(params[:tc])

    render json: { error: "Not authorized" }, status: :unauthorized
    false
  end

  def session_code_param
    params[:ss].presence || params.dig(:dispute, :ss).presence || params.dig(:dispute, :session_code).presence
  end

  def description_param
    params[:description].presence || params.dig(:dispute, :description).to_s
  end

  def assigned_staff_provided?
    params.key?(:assigned_staff) || (params[:dispute].respond_to?(:key?) && params[:dispute].key?(:assigned_staff))
  end

  def assigned_staff_codes
    raw = params[:assigned_staff]
    raw = params.dig(:dispute, :assigned_staff) if raw.nil?
    Array(raw).flat_map { |value| value.to_s.split(",") }.map(&:strip).reject(&:blank?)
  end

  def therapists_from(codes)
    return [] if codes.blank?

    found = codes.uniq.map { |code| [code, Therapist.find_by(code: code)] }
    missing = found.select { |_code, therapist| therapist.nil? }.map(&:first)
    if missing.any?
      render json: { error: "Therapist not found" }, status: :not_found
      return
    end
    found.map(&:last)
  end

  def resolution_text
    source = params[:resolution].presence || params.dig(:dispute, :resolution)
    return "" unless source.respond_to?(:[])

    source[:text].to_s.presence || source["text"].to_s
  end

  def resolution_urls
    source = params[:resolution].presence || params.dig(:dispute, :resolution)
    raw = source.respond_to?(:[]) ? (source[:image_urls] || source["image_urls"]) : []
    Array(raw).map { |url| url.to_s.strip }.reject(&:blank?)
  end

  def thread_source
    params[:thread].presence || params.dig(:dispute, :thread) || ActionController::Parameters.new
  end

  def thread_name
    thread_source[:name].to_s.strip.presence || params[:name].to_s.strip
  end

  def thread_text
    thread_source[:text].to_s.strip.presence || params[:text].to_s.strip
  end

  def thread_image_url
    thread_source[:image_url].to_s.strip.presence || params[:image_url].to_s.strip
  end

  def thread_index
    raw = params[:index].to_s
    return nil unless raw.match?(/\A\d+\z/)

    raw.to_i
  end

  def upload_dispute_image(file, name)
    Pos::ImgbbUpload.call(file, name: name)[:img_url]
  rescue Pos::ImgbbUpload::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
    nil
  end

  def mark_session_disputed(session_record)
    history = (session_record.session_history || {}).to_h.stringify_keys
    history["disputed"] = true
    session_record.update_columns(session_history: history)
  end
end
