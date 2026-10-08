class Therapist < ApplicationRecord
    has_many :sessions, dependent: :destroy
    has_many :session_therapists, dependent: :destroy
    has_many :sessions, through: :session_therapists
end
