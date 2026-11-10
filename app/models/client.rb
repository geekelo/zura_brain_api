class Client < ApplicationRecord
    has_many :sessions, dependent: :destroy

    def self.search(term)
        return all if term.blank?

        pattern = like_pattern(term)
        where(
            "name ILIKE :term OR phone ILIKE :term OR EXISTS (" \
            "SELECT 1 FROM unnest(other_phones) AS number WHERE number ILIKE :term)",
            term: pattern
        )
    end

    def self.like_pattern(value)
        "%#{sanitize_sql_like(value.to_s.strip)}%"
    end
    private_class_method :like_pattern
end
