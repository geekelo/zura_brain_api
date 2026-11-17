class AddSanctionsTotalsToTherapistAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :therapist_accounts, :total_sanctions_payin, :decimal, precision: 10, scale: 2
    add_column :therapist_accounts, :total_sanctions_payout, :decimal, precision: 10, scale: 2
  end
end
