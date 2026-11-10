class SessionActivity < ApplicationRecord
  belongs_to :session
  belongs_to :therapist
end
