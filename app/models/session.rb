class Session < ApplicationRecord
  belongs_to :client

  belongs_to :session_creator,
             class_name: "Therapist",
             optional: true

  has_many :session_therapists,
           dependent: :destroy

  has_many :therapists,
           through: :session_therapists

  accepts_nested_attributes_for :session_therapists,
                                allow_destroy: true
end