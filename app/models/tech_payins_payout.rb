class TechPayinsPayout < ApplicationRecord
  self.inheritance_column = :_type_disabled

  belongs_to :extra_account, optional: true
  belongs_to :session_therapist, optional: true
end
