class Therapist < ApplicationRecord
    validates :work_name, presence: true, uniqueness: true
    validates :code, presence: true, uniqueness: true

    has_many :sessions, dependent: :destroy
    has_many :session_therapists, dependent: :destroy
    has_many :session_activities, dependent: :destroy
    has_many :sessions, through: :session_therapists
    has_many :sanctions, dependent: :nullify
end
