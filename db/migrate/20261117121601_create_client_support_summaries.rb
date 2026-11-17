class CreateClientSupportSummaries < ActiveRecord::Migration[7.2]
  def change
    create_table :client_support_summaries do |t|
      t.integer :month
      t.integer :year
      t.decimal :total_amount_payin, precision: 10, scale: 2
      t.decimal :amount_settled_payin, precision: 10, scale: 2
      t.decimal :amount_unsettled_payin, precision: 10, scale: 2
      t.decimal :total_amount_payout, precision: 10, scale: 2
      t.decimal :amount_settled_payout, precision: 10, scale: 2
      t.decimal :amount_unsettled_payout, precision: 10, scale: 2

      t.timestamps
    end
  end
end
