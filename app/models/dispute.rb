class Dispute < ApplicationRecord
  belongs_to :session
  has_many :dispute_therapists, dependent: :destroy
  has_many :assigned_staff, through: :dispute_therapists, source: :therapist

  validates :description, presence: true
  validate :thread_is_a_list

  before_validation :normalize_resolution

  def as_api_json
    {
      "id" => id,
      "description" => description,
      "thread" => Array(thread).map { |entry| self.class.thread_entry(entry) },
      "resolved" => resolved,
      "resolution" => {
        "text" => resolution.is_a?(Hash) ? resolution.stringify_keys["text"].to_s : "",
        "image_urls" => resolution.is_a?(Hash) ? Array(resolution.stringify_keys["image_urls"]) : []
      },
      "assigned_staff" => assigned_staff.map { |therapist| { "work_name" => therapist.work_name, "code" => therapist.code } },
      "session_code" => session&.session_code,
      "client_name" => session&.client&.name,
      "created_at" => created_at&.utc&.iso8601(0)
    }
  end

  def self.thread_entry(entry)
    data = entry.to_h.stringify_keys
    {
      "name" => data["name"].to_s,
      "text" => data["text"].to_s,
      "datetime" => data["datetime"].to_s,
      "image_url" => data["image_url"].to_s
    }
  end

  private

  def thread_is_a_list
    return if thread.is_a?(Array)

    errors.add(:thread, "must be a list")
  end

  def normalize_resolution
    data = resolution.is_a?(Hash) ? resolution.stringify_keys : {}
    urls = Array(data["image_urls"]).map { |url| url.to_s.strip }.reject(&:blank?)
    self.resolution = { "text" => data["text"].to_s, "image_urls" => urls }
  end
end
