module Pos
  class ClearTip
    def self.call(session_therapist:)
      new(session_therapist).call
    end

    def self.periods_for(session_therapist)
      rows = session_therapist.extra_accounts.to_a + session_therapist.tech_payins_payouts.to_a
      rows.filter_map { |row| [row.created_at.month, row.created_at.year] if row.created_at }.uniq
    end

    def self.delete_accounts!(session_therapist)
      extra_ids = session_therapist.extra_accounts.pluck(:id)
      techs = TechPayinsPayout.where(session_therapist: session_therapist)
      techs = techs.or(TechPayinsPayout.where(extra_account_id: extra_ids)) if extra_ids.any?
      techs.destroy_all
      session_therapist.extra_accounts.destroy_all
    end

    def self.refresh!(therapist, occurred_on, periods)
      if therapist && occurred_on
        Pos::UpdateTherapistAccount.call(
          therapist: therapist,
          month: occurred_on.month,
          year: occurred_on.year
        )
      end
      Array(periods).each do |month, year|
        Pos::UpdateExtraAccountSummary.call(month: month, year: year)
        Pos::UpdateTechAccountSummary.call(month: month, year: year)
      end
    end

    def initialize(session_therapist)
      @session_therapist = session_therapist
    end

    def call
      periods = self.class.periods_for(@session_therapist)
      therapist = @session_therapist.therapist
      occurred_on = @session_therapist.session&.session_date || Time.current

      ActiveRecord::Base.transaction do
        self.class.delete_accounts!(@session_therapist)
        @session_therapist.update!(tip_amount: nil, tip_balance: nil)
      end

      self.class.refresh!(therapist, occurred_on, periods)
      @session_therapist
    end
  end
end
