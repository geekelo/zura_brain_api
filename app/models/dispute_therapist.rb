class DisputeTherapist < ApplicationRecord
  belongs_to :dispute
  belongs_to :therapist
end
