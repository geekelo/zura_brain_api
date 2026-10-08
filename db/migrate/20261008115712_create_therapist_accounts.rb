class CreateTherapistAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :therapist_accounts do |t|
      t.references :therapist, null: false, foreign_key: true
      t.integer :month
      t.integer :year
      t.decimal :total_therapist_payin
      t.decimal :total_tip_inflow
      t.decimal :total_therapist_payout
      t.decimal :balance

      t.timestamps
    end
  end
end
