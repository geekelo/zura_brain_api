# app/services/pos/therapist_lookup.rb

module Pos
  class TherapistLookup
    def self.name_for_code(code)
      ::Therapist.find_by(code: code)&.work_name
    end

    def self.id_for_code(code)
      ::Therapist.find_by(code: code)&.id
    end
  end
end
