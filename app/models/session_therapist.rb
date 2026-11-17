class SessionTherapist < ApplicationRecord
  belongs_to :session
  belongs_to :therapist
  has_many :extra_accounts, dependent: :destroy
end
