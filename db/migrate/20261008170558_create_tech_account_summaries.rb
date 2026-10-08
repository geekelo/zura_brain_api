class CreateTechAccountSummaries < ActiveRecord::Migration[7.2]
  def change
    create_table :tech_account_summaries do |t|
      t.integer :month
      t.integer :year
      t.decimal :total_tech_account_inflow
      t.decimal :total_tech_payin_inflow
      t.decimal :total_tech_payout_outflow
      t.decimal :balance

      t.timestamps
    end
  end
end
