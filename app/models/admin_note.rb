class AdminNote < ApplicationRecord
  belongs_to :client, optional: true
  belongs_to :session, optional: true
  belongs_to :therapist, optional: true
  belongs_to :creator, class_name: "Therapist", optional: true
end
