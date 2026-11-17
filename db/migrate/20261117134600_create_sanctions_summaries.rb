class CreateSanctionsSummaries < ActiveRecord::Migration[7.2]
  def change
    create_table :sanctions_summaries do |t|
      t.integer :month
      t.integer :year
      t.decimal :total_payin, precision: 10, scale: 2
      t.decimal :total_payout, precision: 10, scale: 2
      t.decimal :total_balance, precision: 10, scale: 2

      t.timestamps
    end
  end
end
