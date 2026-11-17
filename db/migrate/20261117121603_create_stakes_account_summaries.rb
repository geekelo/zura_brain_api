class CreateStakesAccountSummaries < ActiveRecord::Migration[7.2]
  def change
    create_table :stakes_account_summaries do |t|
      t.integer :month
      t.integer :year
      t.decimal :total_amount, precision: 10, scale: 2
      t.decimal :amount_settled, precision: 10, scale: 2
      t.decimal :amount_unsettled, precision: 10, scale: 2

      t.timestamps
    end
  end
end
