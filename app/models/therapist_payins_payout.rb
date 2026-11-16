class TherapistPayinsPayout < ApplicationRecord
  self.inheritance_column = :_type_disabled

  belongs_to :therapist
end
