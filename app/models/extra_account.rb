class ExtraAccount < ApplicationRecord
  self.inheritance_column = :_type_disabled

  belongs_to :session_therapist
  has_one :tech_payins_payout, foreign_key: :extra_account_id, dependent: :destroy
end
