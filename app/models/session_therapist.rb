class SessionTherapist < ApplicationRecord
  belongs_to :session
  belongs_to :therapist
  has_one :extra_account, dependent: :destroy
end
