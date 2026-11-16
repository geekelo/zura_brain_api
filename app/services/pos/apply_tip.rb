module Pos
  class ApplyTip
    def self.call(session_therapist:, tip_amount:)
      new(session_therapist, tip_amount).call
    end

    def initialize(session_therapist, tip_amount)
      @session_therapist = session_therapist
      @tip_amount = BigDecimal(tip_amount.to_s)
    end

    def call
      therapist_share = @tip_amount / 2
      extra_account_amount = @tip_amount / 2
      extra_amount = extra_account_amount * BigDecimal("0.8")
      tech_amount = extra_account_amount * BigDecimal("0.2")

      extra_account = nil
      tech_account = nil

      ActiveRecord::Base.transaction do
        @session_therapist.update!(
          tip_amount: @tip_amount,
          tip_balance: therapist_share
        )

        extra_account = ExtraAccountPayinPayout.find_or_initialize_by(session_therapist: @session_therapist, type: "payin")
        extra_account.update!(amount: extra_amount, description: "Tip for #{@session_therapist.therapist.work_name}")

        tech_account = TechPayinPayout.find_or_initialize_by(extra_account: extra_account, type: "payin")
        tech_account.update!(amount: tech_amount, description: "Tip for #{@session_therapist.therapist.work_name}")

        occurred_on = @session_therapist.session.session_date || Time.current
        Pos::UpdateTherapistAccount.call(
          therapist: @session_therapist.therapist,
          month: occurred_on.month,
          year: occurred_on.year
        )
        Pos::UpdateTechAccountSummary.call(
          month: tech_account.created_at.month,
          year: tech_account.created_at.year
        )
        Pos::UpdateExtraAccountSummary.call(
          month: extra_account.created_at.month,
          year: extra_account.created_at.year
        )
      end

      {
        session_therapist: @session_therapist,
        extra_account: extra_account,
        tech_account: tech_account
      }
    end
  end
end
