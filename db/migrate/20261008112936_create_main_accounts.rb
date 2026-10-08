class CreateMainAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :main_accounts do |t|
      t.integer :month
      t.integer :year
      t.decimal :total_session_inflow
      t.decimal :total_lunez_inflow
      t.decimal :total_main_account_outflow
      t.decimal :balance

      t.timestamps
    end
  end
end
