class SessionTherapist < ApplicationRecord
  belongs_to :session
  belongs_to :therapist
  has_many :extra_accounts, dependent: :destroy

  after_commit :refresh_session_tipped

  private

  def refresh_session_tipped
    record = Session.find_by(id: session_id)
    record&.refresh_tipped!
  end
end

