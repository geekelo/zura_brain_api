class CreateLunezAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :lunez_accounts do |t|
      t.integer :month
      t.integer :year
      t.decimal :total_inflow
      t.decimal :balance

      t.timestamps
    end
  end
end
