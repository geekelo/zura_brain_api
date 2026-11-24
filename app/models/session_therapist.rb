class SessionTherapist < ApplicationRecord
  belongs_to :session
  belongs_to :therapist
  has_many :tech_payins_payouts, dependent: :destroy
  has_many :extra_accounts, dependent: :destroy

  before_destroy :remember_tip_accounts, prepend: true
  after_commit :refresh_session_tipped
  after_commit :refresh_removed_tip_accounts, on: :destroy

  private

  def refresh_session_tipped
    record = Session.find_by(id: session_id)
    record&.refresh_tipped!
  end

  def remember_tip_accounts
    @removed_tip_periods = Pos::ClearTip.periods_for(self)
    @removed_tip_therapist = therapist
    @removed_tip_on = session&.session_date || Time.current
  end

  def refresh_removed_tip_accounts
    Pos::ClearTip.refresh!(@removed_tip_therapist, @removed_tip_on, @removed_tip_periods)
  end
end

