class SessionTherapist < ApplicationRecord
  belongs_to :session
  belongs_to :therapist
end
