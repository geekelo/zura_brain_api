class SessionTherapist < ApplicationRecord
  belongs_to :session
  belongs_to :therapist
  has_many :extra_account_payin_payouts,
           class_name: "ExtraAccountPayinPayout",
           dependent: :destroy
end
