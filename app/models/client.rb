class Client < ApplicationRecord
    has_many :sessions, dependent: :destroy
end
