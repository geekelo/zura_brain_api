class CreateExtraAccountSummaries < ActiveRecord::Migration[7.2]
  def change
    create_table :extra_account_summaries do |t|
      t.integer :month
      t.integer :year
      t.decimal :total_extra_account_inflow
      t.decimal :total_extra_account_outflow
      t.decimal :balance

      t.timestamps
    end
  end
end
